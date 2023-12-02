#!/bin/sh

cargo build --example 3d --target x86_64-pc-windows-gnu &&
exec target/x86_64-pc-windows-gnu/debug/examples/3d.exe
