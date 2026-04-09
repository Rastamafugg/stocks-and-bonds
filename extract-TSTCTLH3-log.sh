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
DEST_DIR="$SCRIPT_DIR/logs"
HARNESS_SOURCE="TSTCTLH3.log"
HARNESS_DEST="$DEST_DIR/TSTCTLH3.log"
BOOTWAIT_SOURCE="bootWaitReady.log"
BOOTWAIT_DEST="$DEST_DIR/bootWaitReady.log"

if ! command -v os9 >/dev/null 2>&1; then
  echo "ERROR: ToolShed os9 utility not found on PATH."
  exit 1
fi

if [ ! -f "$IMAGE_PATH" ]; then
  echo "ERROR: Disk image not found: $IMAGE_PATH"
  exit 1
fi

mkdir -p "$DEST_DIR"

echo "Extracting $HARNESS_SOURCE from $IMAGE_PATH"
os9 copy -l -r "$IMAGE_PATH,$HARNESS_SOURCE" "$HARNESS_DEST"
echo "Wrote $HARNESS_DEST"

echo "Extracting $BOOTWAIT_SOURCE from $IMAGE_PATH"
os9 copy -l -r "$IMAGE_PATH,$BOOTWAIT_SOURCE" "$BOOTWAIT_DEST"
echo "Wrote $BOOTWAIT_DEST"
