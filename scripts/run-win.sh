#!/bin/sh

# Builds for Windows and runs the executable. Native linux binary has much worse
# performance in WSL2 than the Windows binary.

NAME=$1

cargo build --example $NAME --target x86_64-pc-windows-gnu &&
exec target/x86_64-pc-windows-gnu/debug/examples/$NAME.exe
