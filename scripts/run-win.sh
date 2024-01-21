#!/bin/bash

set -euo pipefail

# Builds for Windows and runs the executable. Native linux binary has much worse
# performance in WSL2 than the Windows binary.

NAME=$1

cargo build --example $NAME --target x86_64-pc-windows-gnu

# Set CARGO_MANIFEST_DIR so that the Windows binary can find the assets
# directory.
export CARGO_MANIFEST_DIR="/home/sidney/code/helium3-rust"
export WSLENV=CARGO_MANIFEST_DIR

exec target/x86_64-pc-windows-gnu/debug/examples/$NAME.exe
