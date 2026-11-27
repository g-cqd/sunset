#!/usr/bin/env bash
# Automated WebKit engine update, build, test, and release (roadmap 0115, ADR-0127).
#
# Runs on a Mac with the warm WebKit build tree ($SUNSET_WEBKIT, ~40 GB) and access to the signing VM (gcqd-dev):
#   1. Checks whether an update is due:
#        --mode=daily   runs only if `Scripts/webkit.sh behind` reports a security advisory newer than Engine/WebKit/base
#        --mode=weekly  runs unconditionally (default)
#        --mode=force   runs unconditionally (alias for weekly)
#        --dry-run      runs `webkit.sh behind` + `webkit.sh check` only; makes no commits, tags, or releases
#   2. Verifies the Sunset working tree is clean on `main` and level with `origin/main` (refuses to clobber active work).
#   3. Runs `Scripts/webkit.sh update [COMMIT]`: fetches WebKit main, applies patches (dropping any upstreamed), builds
#      Release WebKit, runs TestWebKitAPI + layout tests against Engine/WebKit/known-failures, moves Engine/WebKit/base
#      and re-exports patches only if everything passes.
#   4. Commits the updated Engine/WebKit/base + patches + release notes (auto-incrementing the next alpha/patch tag),
#      pushes signed commits via push-vm.sh (Gigi + GPG 9FE7C7E8522EE497), creates and pushes the GPG-signed tag.
#   5. Builds and notarizes both variants (native + WebKit), builds both SSDLTA2 `.deltas` archives, signs
#      `release-index.json` + `.sig` on gcqd-dev, verifies SHA-256 + Ed25519 signature, and publishes the GitHub release.
#   6. On failure at any step: leaves `main` untouched (if before push) and records a diagnostic report in a GitHub issue.
#
#   Scripts/webkit-auto-update.sh [--mode=daily|weekly|force] [--dry-run] [--commit=SHA] [--no-release]
set -euo pipefail
cd "$(dirname "$0")/.."
repo="$PWD"

mode="weekly"
dry_run=0
commit=""
do_release=1

for arg in "$@"; do
    case "$arg" in
        --mode=*) mode="${arg#--mode=}" ;;
        --dry-run) dry_run=1 ;;
        --commit=*) commit="${arg#--commit=}" ;;
        --no-release) do_release=0 ;;
        -h|--help) sed -n '2,23p' "$0"; exit 0 ;;
        *) echo "webkit-auto-update: unknown argument: $arg" >&2; exit 2 ;;
    esac
done

case "$mode" in
    daily|weekly|force) ;;
    *) echo "webkit-auto-update: invalid --mode=$mode (use daily, weekly, or force)" >&2; exit 2 ;;
esac

# Single-instance lock so overlapping launchd triggers never race on the WebKit build tree.
lock_dir="${TMPDIR:-/tmp}/sunset-webkit-auto-update.lock"
if ! mkdir "$lock_dir" 2>/dev/null; then
    echo "webkit-auto-update: another run holds $lock_dir; exiting" >&2
    exit 0
fi
trap 'rm -rf "$lock_dir"' EXIT

sign_host="${SUNSET_SIGN_HOST:-gcqd-dev}"
push_vm="${SUNSET_PUSH_VM:-$HOME/.local/share/sunset-agent/push-vm.sh}"
vm_subpath="${SUNSET_VM_SUBPATH:-Developer/g-cqd/sunset}"
log_dir="${SUNSET_WEBKIT_LOG_DIR:-$HOME/Library/Logs/Sunset}"
mkdir -p "$log_dir"
run_log="$log_dir/webkit-auto-update-$(date +%Y%m%d-%H%M%S).log"

log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$run_log"
}

report_failure() {
    local stage="$1" detail="$2"
    log "FAILED at stage=$stage: $detail"
    local title="Automated WebKit update failed ($stage)"
    local body
    # shellcheck disable=SC2016 # literal Markdown code fences
    body="$(printf 'Automated WebKit update failed at **%s** on %s.\n\n```\n%s\n```\n' "$stage" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$detail")"
    # Best-effort GitHub issue via the signing VM (credentials stay in the VM).
    ssh -o ConnectTimeout=8 "$sign_host" "gh issue create --repo g-cqd/sunset --title $(printf '%q' "$title") --body $(printf '%q' "$body")" \
        >> "$run_log" 2>&1 || true
}

# Compute the next tag from the latest v* tag:
#   v0.1.0-alpha.15 -> v0.1.0-alpha.16
#   v0.1.0          -> v0.1.1
next_tag() {
    local latest="$1"
    if [[ "$latest" =~ ^(.*[^0-9])([0-9]+)$ ]]; then
        printf '%s%d\n' "${BASH_REMATCH[1]}" "$((BASH_REMATCH[2] + 1))"
    else
        echo "webkit-auto-update: cannot increment tag '$latest'" >&2
        return 1
    fi
}

log "starting (mode=$mode dry_run=$dry_run commit=${commit:-main} release=$do_release)"

# Step 1: check advisories (always logged; gates --mode=daily).
advisory_due=0
behind_out=""
set +e
behind_out="$(Scripts/webkit.sh behind 2>&1)"
behind_code=$?
set -e
log "behind (exit $behind_code): $behind_out"
if [ "$behind_code" -eq 1 ]; then
    advisory_due=1
elif [ "$behind_code" -ne 0 ]; then
    log "advisory check errored (exit $behind_code); continuing only if weekly/force"
fi

if [ "$mode" = "daily" ] && [ "$advisory_due" -eq 0 ]; then
    log "daily mode and no newer WebKit security advisory; nothing to do."
    exit 0
fi

if [ "$dry_run" -eq 1 ]; then
    log "dry-run: checking patch series against ${commit:-WebKit main}"
    if [ -n "$commit" ]; then
        Scripts/webkit.sh check "$commit" 2>&1 | tee -a "$run_log"
    else
        Scripts/webkit.sh check 2>&1 | tee -a "$run_log"
    fi
    log "dry-run complete."
    exit 0
fi

# Step 2: safety guards on the local Sunset repo before touching anything.
branch="$(git rev-parse --abbrev-ref HEAD)"
if [ "$branch" != "main" ]; then
    log "refusing to run: repo is on branch '$branch', not 'main'"
    exit 0
fi
if [ -n "$(git status --porcelain)" ]; then
    log "refusing to run: working tree has uncommitted changes"
    exit 0
fi
git fetch -q origin main --tags
behind_main="$(git rev-list --count HEAD..origin/main)"
ahead_main="$(git rev-list --count origin/main..HEAD)"
if [ "$ahead_main" -ne 0 ]; then
    log "refusing to run: local main is $ahead_main commit(s) ahead of origin/main"
    exit 0
fi
if [ "$behind_main" -ne 0 ]; then
    log "fast-forwarding local main ($behind_main commit(s))"
    git merge -q --ff-only origin/main
fi

# Verify VM is reachable and unlocked before investing ~1h in a WebKit build.
if ! ssh -o ConnectTimeout=8 "$sign_host" 'ssh-add -l >/dev/null 2>&1 && test -f ~/.config/sunset-signing/release-index-main.pem' >/dev/null 2>&1; then
    report_failure "preflight" "Signing host $sign_host is unreachable, locked, or missing release-index-main.pem"
    exit 1
fi

old_base="$(cat Engine/WebKit/base)"
old_patches="$(find Engine/WebKit/patches -name '*.patch' | wc -l | tr -d ' ')"

# Step 3: run Scripts/webkit.sh update (fetch, apply, build, test, move base & export patches).
update_out="$(mktemp)"
set +e
if [ -n "$commit" ]; then
    Scripts/webkit.sh update "$commit" > "$update_out" 2>&1
else
    Scripts/webkit.sh update > "$update_out" 2>&1
fi
update_code=$?
set -e
cat "$update_out" >> "$run_log"
if [ "$update_code" -ne 0 ]; then
    tail_err="$(tail -40 "$update_out")"
    rm -f "$update_out"
    report_failure "webkit-update" "$tail_err"
    exit 1
fi
update_summary="$(cat "$update_out")"
rm -f "$update_out"

new_base="$(cat Engine/WebKit/base)"
new_patches="$(find Engine/WebKit/patches -name '*.patch' | wc -l | tr -d ' ')"
if [ "$new_base" = "$old_base" ] && [ -z "$(git status --porcelain Engine/WebKit)" ]; then
    log "WebKit is already at $new_base with no patch changes; nothing to release."
    exit 0
fi
log "WebKit updated: ${old_base:0:10} ($old_patches patches) -> ${new_base:0:10} ($new_patches patches)"

# Step 4: commit engine update, generate release notes, push signed commits via VM, and tag.
short_new="${new_base:0:10}"
short_old="${old_base:0:10}"
reason="scheduled weekly update"
[ "$advisory_due" -eq 0 ] || reason="security advisory ($behind_out)"

git add Engine/WebKit/base Engine/WebKit/patches
git -c user.name=Gigi -c user.email=42325924+g-cqd@users.noreply.github.com commit -q \
    -m "WebKit: update base to $short_new ($new_patches patches; $reason)"

latest_tag="$(git tag --list 'v*' --sort=-v:refname | head -1)"
tag="$(next_tag "$latest_tag")"

if [ "$do_release" -eq 1 ]; then
    notes_file="docs/releases/$tag.md"
    cat > "$notes_file" <<EOF
Automated WebKit engine update ($reason). Expect rough edges, and settings or saved state that a later build may not read.

**What changed since ${latest_tag#v}.**
- **WebKit engine updated** from \`$short_old\` ($old_patches patches) to \`$short_new\` ($new_patches patches). All
  TestWebKitAPI and layout test suites passed against \`Engine/WebKit/known-failures\`.

**Two variants of one app.**
- **Sunset** (\`Sunset-$tag-…\`): pages on the system's WebKit, the one Safari uses.
- **Sunset with its own WebKit** (\`Sunset-WebKit-$tag-…\`): the same app with WebKit's main branch at $short_new
  and $new_patches patches of ours. Switch between them in Settings › General › Updates › Web engine.

**Install.** Unzip, move the app to Applications, open it. Both are signed with a Developer ID and notarised by Apple. They
need macOS 26 or later and a Mac with Apple silicon.

**Check the download.** \`shasum -a 256 -c NAME.zip.sha256\` in the folder holding both files.

Report what breaks in the repository's issues.
EOF
    git add "$notes_file"
    git -c user.name=Gigi -c user.email=42325924+g-cqd@users.noreply.github.com commit -q \
        -m "Release notes for $tag"
fi

if ! "$push_vm" "$repo" "$vm_subpath" >> "$run_log" 2>&1; then
    report_failure "push" "push-vm.sh failed; see local log $run_log"
    exit 1
fi

if [ "$do_release" -eq 0 ]; then
    log "done (--no-release); pushed WebKit base $short_new to main."
    exit 0
fi

# Create GPG-signed tag on VM and fetch back.
build="$(git rev-list --count HEAD)"
# shellcheck disable=SC2029 # client-side expansion of verified local variables is intentional
ssh "$sign_host" "cd ~/$vm_subpath && git fetch -q origin && git checkout -q main && git reset --hard -q origin/main && git tag -s '$tag' -m 'Sunset ${tag#v} (build $build)' && git push origin '$tag'" >> "$run_log" 2>&1
git fetch -q --tags origin

# Step 5: package both variants (native + WebKit), notarize, build SSDLTA2 deltas, sign index on VM, publish release.
dist="$repo/.build/dist-auto"
rm -rf "$dist" "$dist.build" "$repo/.build/app-package" "$repo/.build/app-webkit-release"
if ! Scripts/package-release.sh "$tag" "$dist" >> "$run_log" 2>&1; then
    report_failure "package-native" "Scripts/package-release.sh $tag failed (see $run_log)"
    exit 1
fi

notes_tmp="$(mktemp)"
{ printf 'Build %s.\n\n' "$build"; cat "docs/releases/$tag.md"; } > "$notes_tmp"
if ! SUNSET_SIGN_HOST="$sign_host" Scripts/package-variants.sh "$tag" "$dist" "$notes_tmp" >> "$run_log" 2>&1; then
    rm -f "$notes_tmp"
    report_failure "package-variants" "Scripts/package-variants.sh $tag failed (see $run_log)"
    exit 1
fi

# Upload assets via VM and publish GitHub release.
remote_dist="/tmp/sunset-release-$tag"
remote_notes="/tmp/sunset-release-$tag-notes.md"
# shellcheck disable=SC2029 # client-side expansion of verified local variables is intentional
tar -cf - -C "$dist" . | ssh "$sign_host" "rm -rf '$remote_dist' && mkdir -p '$remote_dist' && tar -xf - -C '$remote_dist'"
scp -q "$notes_tmp" "$sign_host:$remote_notes"
rm -f "$notes_tmp"

prerelease_flag=""
case "$tag" in *-*) prerelease_flag="--prerelease" ;; esac
# shellcheck disable=SC2029 # client-side expansion of verified local variables is intentional
# Release.yml may have published the native variant first: then this run's assets (both variants, one index) replace its.
if ! ssh "$sign_host" "cd ~/$vm_subpath && if gh release view '$tag' --repo g-cqd/sunset > /dev/null 2>&1; then gh release upload '$tag' '$remote_dist'/* --clobber --repo g-cqd/sunset && gh release edit '$tag' --repo g-cqd/sunset --title 'Sunset ${tag#v} (build $build)' --notes-file '$remote_notes' $prerelease_flag; else gh release create '$tag' '$remote_dist'/* --repo g-cqd/sunset --title 'Sunset ${tag#v} (build $build)' --notes-file '$remote_notes' --verify-tag $prerelease_flag; fi && rm -rf '$remote_dist' '$remote_notes'" >> "$run_log" 2>&1; then
    report_failure "publish-release" "gh release create $tag failed (see $run_log)"
    exit 1
fi

rm -rf "$dist" "$dist.build" "$repo/.build/app-package" "$repo/.build/app-webkit-release"
log "published $tag (build $build) with WebKit $short_new ($new_patches patches); summary: $update_summary"
