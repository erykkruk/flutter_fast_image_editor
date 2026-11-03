#!/usr/bin/env bash
# Fails when the native library exports a symbol without the image_edit_ prefix.
# iOS links plugins statically, so an exported stb_image or generic name collides
# with any other plugin that has the same one, as flutter_bicubic_resize did.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
object_file="$(mktemp -d)/image_edit.o"

c++ -std=c++11 -w -c "$repo_root/src/image_edit.cpp" -o "$object_file"

# Mach-O prefixes C symbols with an underscore, ELF does not. Weak (W, V) C++
# standard library instantiations belong to the toolchain, not to this library.
exported="$(nm -g --defined-only "$object_file" | awk '$2 == "T" || $2 == "D" || $2 == "B" || $2 == "S" { print $3 }' | sed 's/^_//')"

if [ -z "$exported" ]; then
  echo "No exported symbols found, the check is not looking at the right thing" >&2
  exit 1
fi

foreign="$(echo "$exported" | grep -v '^image_edit_' || true)"
if [ -n "$foreign" ]; then
  echo "Exported symbols without the image_edit_ prefix:" >&2
  echo "$foreign" >&2
  exit 1
fi

echo "All exported symbols are prefixed:"
echo "$exported"
