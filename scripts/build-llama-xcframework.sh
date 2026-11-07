#!/bin/zsh
# Builds TranslateCore/Frameworks/llama.xcframework (macOS only) from a pinned
# llama.cpp tag using the upstream build-xcframework.sh. Requires Xcode and cmake.
#
#   LLAMA_CPP_DIR   where to clone or find llama.cpp (default: .build/llama.cpp)
set -euo pipefail

readonly tag=v0.9.0
readonly root=${0:A:h:h}
readonly source_dir=${LLAMA_CPP_DIR:-$root/.build/llama.cpp}
readonly destination=$root/TranslateCore/Frameworks/llama.xcframework

if [[ ! -d $source_dir/.git ]]; then
    git clone --depth 1 --branch $tag https://github.com/ggml-org/llama.cpp "$source_dir"
fi
cd "$source_dir"
if [[ $(git describe --tags --exact-match 2>/dev/null) != $tag ]]; then
    git fetch --depth 1 origin tag $tag
    git checkout --quiet $tag
fi

./build-xcframework.sh macos

rm -rf "$destination"
mkdir -p "${destination:h}"
cp -R build-apple/llama.xcframework "$destination"
echo "built $destination from llama.cpp $tag"
