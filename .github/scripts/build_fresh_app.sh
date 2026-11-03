#!/usr/bin/env bash
# Builds a brand new Flutter app that depends on this plugin and on
# flutter_bicubic_resize. A fresh app gets the defaults library users get (Swift
# Package Manager, current AGP), and both plugins compile stb_image, which only
# links when neither exports its symbols.
#
# Usage: build_fresh_app.sh ios true|false   (use Swift Package Manager or not)
#        build_fresh_app.sh android
set -euo pipefail

target="$1"
swiftpm="${2:-false}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
work_dir="$(mktemp -d)"
package_dir="$work_dir/fast_image_editor"
app_dir="$work_dir/ci_probe"

# pub archives dereference the ios/src symlink, a path dependency does not, so
# copy the package with links resolved to build what pub.dev users receive.
rsync -aL --exclude .git --exclude .dart_tool --exclude build --exclude example \
  "$repo_root/" "$package_dir/"

flutter create --platforms="$target" --project-name ci_probe "$app_dir"
cd "$app_dir"
flutter pub add fast_image_editor --path "$package_dir"
flutter pub add flutter_bicubic_resize
perl -0pi -e "s/^flutter:\n/flutter:\n  config:\n    enable-swift-package-manager: $swiftpm\n/m" pubspec.yaml

if [ "$target" = "ios" ]; then
  flutter build ios --simulator --debug
else
  flutter build apk --debug
fi
