#!/bin/bash
# Builds release binaries for Linux and Windows into build/ and zips them for a GitHub release.
# Needs Godot (4.7.x, the same version as the installed export templates) on the PATH.
#   ./build.sh            both platforms
#   ./build.sh linux      just Linux      ./build.sh windows   just Windows
set -euo pipefail
cd "$(dirname "$0")"
VERSION="${VERSION:-$(git describe --tags --always 2>/dev/null || echo dev)}"
what="${1:-all}"
mkdir -p build/linux build/windows

if [ "$what" = "all" ] || [ "$what" = "linux" ]; then
	godot --headless --path . --export-release "Linux" build/linux/CodePrimates.x86_64
	python3 tools/zip_release.py "build/code-primates-$VERSION-linux-x86_64.zip" build/linux/CodePrimates.x86_64
fi
if [ "$what" = "all" ] || [ "$what" = "windows" ]; then
	godot --headless --path . --export-release "Windows Desktop" build/windows/CodePrimates.exe
	python3 tools/zip_release.py "build/code-primates-$VERSION-windows-x86_64.zip" build/windows/CodePrimates.exe
fi
ls -lh build/*.zip
