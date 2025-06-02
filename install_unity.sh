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
echo "Installing Unity version $VERSION with linux-server module..."
unityhub --headless install --version "$VERSION" --module linux-server
echo "Unity installation completed"

echo "Attempting to activate Unity license..."
# Ensure UNITY_USERNAME and UNITY_PASSWORD are set (e.g., from .env file)
if [ -z "$UNITY_USERNAME" ] || [ -z "$UNITY_PASSWORD" ]; then
  echo "Error: UNITY_USERNAME or UNITY_PASSWORD is not set. Cannot activate license."
else
  if [ -n "$UNITY_SERIAL_KEY" ]; then
    echo "Activating with username, password, and serial key..."
    unityhub --headless license --activate -u "$UNITY_USERNAME" -p "$UNITY_PASSWORD" -s "$UNITY_SERIAL_KEY"
    ACTIVATION_EXIT_CODE=$?
  else
    echo "Attempting to activate with username and password (may require a seat for Personal license or be intended for Pro/Plus)..."
    unityhub --headless license --activate -u "$UNITY_USERNAME" -p "$UNITY_PASSWORD"
    ACTIVATION_EXIT_CODE=$?
  fi

  if [ $ACTIVATION_EXIT_CODE -ne 0 ]; then
    echo "Warning: Unity license activation failed with exit code $ACTIVATION_EXIT_CODE."
    echo "Please ensure you have a valid license (e.g., Unity Pro for headless builds, or a Personal license with an available seat)."
    echo "If using a serial key, ensure UNITY_SERIAL_KEY is set in your .env file and is valid."
    # Consider exiting here if activation is critical: exit $ACTIVATION_EXIT_CODE
  else
    echo "Unity license activation attempt completed successfully."
  fi
fi

echo "Stopping Xvfb..."
kill $XVFB_PID
# Wait for Xvfb to terminate, but don't fail if it's already gone
wait $XVFB_PID 2>/dev/null || true
echo "Xvfb stopped."