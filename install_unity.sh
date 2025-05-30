#!/bin/bash
set -ex # Exit immediately if a command exits with a non-zero status, and print commands.

export DISPLAY=:99

echo "Starting Xvfb..."
Xvfb :99 -screen 0 1024x768x24 &
XVFB_PID=$!
# Allow Xvfb to initialize
sleep 5 # Increased sleep duration

echo "Starting D-Bus..."
mkdir -p /var/run/dbus
# Attempt to remove stale pid file if it exists, then start D-Bus
rm -f /var/run/dbus/pid
dbus-daemon --system --fork || echo "Warning: dbus-daemon --system --fork failed or D-Bus may already be running."
# Allow D-Bus to initialize
sleep 5 # Increased sleep duration

echo "Locating unityhub..."
UNITYHUB_BIN=$(which unityhub)

if [ -z "$UNITYHUB_BIN" ]; then
    echo "Error: unityhub command not found in PATH."
    exit 1
fi
echo "Unity Hub binary found at: $UNITYHUB_BIN"

echo "File type of Unity Hub binary:"
file "$UNITYHUB_BIN"

echo "Attempting to list linked libraries for Unity Hub (may not work as expected if it's an AppImage or script):"
ldd "$UNITYHUB_BIN" || echo "Warning: ldd command failed or Unity Hub is not a dynamically linked ELF executable."

echo "Setting Unity install path..."
unityhub --headless install-path --set /opt/unity
echo "Available Unity versions:"
unityhub --headless editors --releases
# Use one of the versions from the output above
VERSION="6000.0.50f1" # This version is used if the above command fails
echo "Installing Unity version $VERSION..."
unityhub --headless install --version $VERSION
echo "Unity installation completed"

echo "Stopping Xvfb..."
kill $XVFB_PID
# Wait for Xvfb to terminate, but don't fail if it's already gone
wait $XVFB_PID 2>/dev/null || true
echo "Xvfb stopped."