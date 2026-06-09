#!/usr/bin/env bash
#
# Host entrypoint: (re)generates the signed apt repo into ../public from the
# .deb files in ../debs. Run this whenever you add new .debs.
#
#   pairs-apt/
#     debs/        <- drop ros-*-pairs-*.deb here
#     keys/        <- private.asc (signing key; gitignored, generated on first run)
#     public/      <- generated static apt repo (published to GitHub Pages)
#
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
IMAGE="pairs-apt-tools"

mkdir -p "$ROOT/debs" "$ROOT/keys" "$ROOT/docs"

echo ">> building tools image..."
docker build -t "$IMAGE" "$SCRIPT_DIR"

echo ">> generating signed apt repo into docs/ ..."
docker run --rm \
  -v "$ROOT/debs":/debs:ro \
  -v "$ROOT/docs":/site \
  -v "$ROOT/keys":/keys \
  "$IMAGE"

echo ">> done. GitHub Pages: deploy from branch -> main -> /docs."
