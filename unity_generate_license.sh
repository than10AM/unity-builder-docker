#!/bin/bash
set -ex # Exit immediately if a command exits with a non-zero status, and print commands.

echo "Starting D-Bus for license generation environment..."
mkdir -p /var/run/dbus
# Attempt to remove stale pid file if it exists, then start D-Bus
rm -f /var/run/dbus/pid
dbus-daemon --system --fork || echo "Warning: dbus-daemon --system --fork failed or D-Bus may already be running."
# Allow D-Bus to initialize
sleep 5 # Increased sleep duration
echo "D-Bus startup attempt complete."

# Path to the Unity Editor executable inside the Docker container
# Ensure this matches the version installed by install_unity.sh
UNITY_EDITOR_PATH="/opt/unity/6000.0.50f1/Editor/Unity"
ALF_OUTPUT_DIR="/license_files" # This directory will be mapped to ./license_files on the host

echo "--- Unity Manual License Activation File Generation ---"

# Check if Unity Editor exists and is executable
if [ ! -x "$UNITY_EDITOR_PATH" ]; then
  echo "Error: Unity Editor not found or not executable at $UNITY_EDITOR_PATH"
  echo "Please ensure Unity has been installed correctly via the 'unity_install' service."
  exit 1
fi

echo "Creating output directory for .alf file: $ALF_OUTPUT_DIR"
mkdir -p "$ALF_OUTPUT_DIR"

echo "Cleaning up potentially conflicting Unity project files in $ALF_OUTPUT_DIR to prevent errors..."
rm -rf "$ALF_OUTPUT_DIR/Assets"
rm -rf "$ALF_OUTPUT_DIR/Library"
rm -rf "$ALF_OUTPUT_DIR/ProjectSettings"
rm -rf "$ALF_OUTPUT_DIR/Packages"

# Navigate to the output directory to ensure the .alf file is generated here
cd "$ALF_OUTPUT_DIR"

echo "Generating manual activation file (.alf)..."
echo "This may take a few moments."

# Use xvfb-run to provide a virtual display for Unity's command-line activation process
# The .alf file is typically created in the current working directory when -createManualActivationFile is used.
xvfb-run --auto-servernum --server-args="-screen 0 1024x768x24" "$UNITY_EDITOR_PATH" \
  -batchmode -nographics -createManualActivationFile -logfile "$ALF_OUTPUT_DIR/activation.log"

# Attempt to find the generated .alf file (e.g., Unity_v2022.3.15f1.alf)
# The exact name depends on the Unity version.
ALF_FILE=$(find . -maxdepth 1 -name 'Unity_v*.alf' -print -quit)

if [ -n "$ALF_FILE" ]; then
  # Make the .alf file and log readable/writable by the host user if needed
  chmod 666 "$ALF_FILE"
  chmod 666 "$ALF_OUTPUT_DIR/activation.log"

  echo ""
  echo "SUCCESS: Manual Activation File generated: $ALF_OUTPUT_DIR/$ALF_FILE"
  echo "The file '$ALF_FILE' and 'activation.log' are now available in the './license_files' directory on your host machine."
  echo ""
  echo "Next Steps for Manual Activation:"
  echo "1. Go to https://license.unity3d.com/manual"
  echo "2. Upload the '$ALF_FILE' file from the './license_files' directory."
  echo "3. Follow the instructions on the website to download your Unity License File (.ulf)."
  echo "4. Once you have the .ulf file, you will need to use it to activate Unity."
  echo "   You can do this manually by placing it in the correct license directory for your OS, or by using a command like:"
  echo "   xvfb-run --auto-servernum --server-args=\"-screen 0 1024x768x24\" \"$UNITY_EDITOR_PATH\" -batchmode -nographics -manualLicenseFile /path/to/your/license.ulf -logfile /dev/stdout"
  echo "   (Ensure you map the .ulf file into the container at '/path/to/your/license.ulf')"
  echo ""
else
  echo "ERROR: Manual Activation File (.alf) was not found in $ALF_OUTPUT_DIR."
  echo "Please check the log file '$ALF_OUTPUT_DIR/activation.log' (available in './license_files' on your host) for details."
  # Attempt to make the log readable/writable by the host user
  if [ -f "$ALF_OUTPUT_DIR/activation.log" ]; then
    chmod 666 "$ALF_OUTPUT_DIR/activation.log"
  fi
  exit 1
fi

echo "License generation script finished."