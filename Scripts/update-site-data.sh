#!/usr/bin/env bash
# Fetches the site data Sunset ships (task t118) into Sources/SunsetSiteData/Resources and records where each came from:
#   the Public Suffix List (publicsuffix.org, MPL 2.0: the file keeps its own notice), from the one address the list asks to
#   be fetched from; Apple's password-manager-resources (MIT: its licence beside it), at the repository's latest commit.
# Then run the tests: `swift test --filter SunsetSiteDataTests` holds the list's own checks.
set -euo pipefail
cd "$(dirname "$0")/.."
out="Sources/SunsetSiteData/Resources"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

curl -fsSL -o "$work/public_suffix_list.dat" https://publicsuffix.org/list/public_suffix_list.dat
git clone -q --depth 1 https://github.com/apple/password-manager-resources.git "$work/pmr"
revision="$(git -C "$work/pmr" log -1 --format='%H %cs')"

cp "$work/public_suffix_list.dat" "$out/"
for file in password-rules.json shared-credentials.json change-password-URLs.json; do
    cp "$work/pmr/quirks/$file" "$out/"
done
cp "$work/pmr/LICENSE.md" "$out/password-manager-resources-LICENSE.md"
cat > "$out/SOURCES.md" <<EOF
# Where the site data comes from

| File | Source | Licence | Fetched |
|---|---|---|---|
| public_suffix_list.dat | https://publicsuffix.org/list/public_suffix_list.dat | MPL 2.0 (its own header) | $(date -u +%F) |
| password-rules.json, shared-credentials.json, change-password-URLs.json | https://github.com/apple/password-manager-resources, commit ${revision} | MIT (password-manager-resources-LICENSE.md) | $(date -u +%F) |
EOF
echo "updated $out (password-manager-resources ${revision})"
