#!/bin/sh
# Writes Sources/SunsetWebModel/AgentVersions.swift: the major versions of the browsers Sunset can appear as,
# read from each vendor's own release feed. Run by a person, when the presets should be brought up to date; the app
# never fetches them (baked into the app when it is compiled).
#
#   Scripts/update-agent-versions.sh
set -eu
cd "$(dirname "$0")/.."

fetch() { curl -fsS -m 20 "$1"; }

chrome="$(fetch "https://versionhistory.googleapis.com/v1/chrome/platforms/mac/channels/stable/versions?pageSize=1" \
    | sed -n 's/.*"version": *"\([0-9]*\)\..*/\1/p' | sed -n 1p)"
firefox="$(fetch "https://product-details.mozilla.org/1.0/firefox_versions.json" \
    | sed -n 's/.*"LATEST_FIREFOX_VERSION": *"\([0-9]*\)\..*/\1/p' | sed -n 1p)"
edge="$(fetch "https://edgeupdates.microsoft.com/api/products" \
    | tr '{' '\n' | grep '"Platform":"MacOS"' | sed -n 's/.*"ProductVersion":"\([0-9]*\)\..*/\1/p' | sed -n 1p)"

for value in "$chrome" "$firefox" "$edge"; do
    case "$value" in
        '' | *[!0-9]*) echo "update-agent-versions: a feed did not give a version (chrome=$chrome firefox=$firefox edge=$edge)" >&2; exit 1 ;;
    esac
done

today="$(date +%Y-%m-%d)"
cat > Sources/SunsetWebModel/AgentVersions.swift <<SWIFT
/// The major versions of the browsers Sunset can appear as: the vendors' own, as their release feeds gave them on
/// $today. Written by \`Scripts/update-agent-versions.sh\`; never fetched while the app runs.
package enum AgentVersions {
    package static let chrome = $chrome
    package static let edge = $edge
    package static let firefox = $firefox
}
SWIFT
echo "chrome $chrome, edge $edge, firefox $firefox, as of $today"
