#!/bin/zsh
# Snapshot outside Documents to avoid macOS NSFileCoordinator stalls in xcodebuild.
set -euo pipefail
ananta_root="$(cd "$(dirname "$0")/.." && pwd)"
ananta_stage="$(mktemp -d /private/tmp/ananta-build.XXXXXX)"
rsync -a --exclude build --exclude SourcesArchive --exclude .git "$ananta_root/" "$ananta_stage/"
xcodebuild -project "$ananta_stage/Ananta.xcodeproj" -scheme Ananta -configuration Debug \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath "$ananta_stage/build" \
  CODE_SIGNING_ALLOWED=NO build
mkdir -p "$ananta_root/build"
ditto "$ananta_stage/build/Build/Products/Debug-iphonesimulator/Hindu App.app" "$ananta_root/build/Hindu App.app"
echo "Simulator app: $ananta_root/build/Hindu App.app"
echo "Build workspace: $ananta_stage"
