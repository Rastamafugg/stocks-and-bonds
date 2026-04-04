#!/bin/bash
set -euo pipefail

SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ "$SOURCE" != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"

IMAGE_PATH="${1:-$SCRIPT_DIR/disks/snbsrc.dsk}"
SOURCE_FILE="${2:-modulelog}"
DEST_DIR="$SCRIPT_DIR/logs"
DEST_PATH="$DEST_DIR/modulelog"

if ! command -v os9 >/dev/null 2>&1; then
  echo "ERROR: ToolShed os9 utility not found on PATH."
  exit 1
fi

if [ ! -f "$IMAGE_PATH" ]; then
  echo "ERROR: Disk image not found: $IMAGE_PATH"
  exit 1
fi

mkdir -p "$DEST_DIR"

echo "Extracting $SOURCE_FILE from $IMAGE_PATH"
os9 copy -l -r "$IMAGE_PATH,$SOURCE_FILE" "$DEST_PATH"
echo "Wrote $DEST_PATH"
