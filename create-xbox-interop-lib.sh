#!/bin/bash
# usage: ./create-xbox-interop-lib.sh <mcpe.apk> <outdir>
# ANDROID_HOME should point to Android SDK with support library 23.1.1
set -e
scriptbase="$(cd "$(dirname "$0")" && pwd)"
apktool -o "$2" d "$1"
cp "$1" "$2/mcpe.apk"
cd "$2"
"$scriptbase/makealib.sh"
