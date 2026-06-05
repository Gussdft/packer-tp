#!/bin/sh
echo "=== System Information ==="
uname -a
echo ""
echo "=== OS Release ==="
cat /etc/os-release
echo ""
echo "=== System Info File ==="
cat /system-info.txt
