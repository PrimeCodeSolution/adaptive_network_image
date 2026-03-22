#!/usr/bin/env bash
set -e

cd example
flutter build web
python3 -m http.server 8080 -d build/web
