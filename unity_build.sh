#!/bin/bash

# Script to build a Unity project for Windows, accepting login credentials.

# --- !!! IMPORTANT CONFIGURATION !!! ---
# SET THE PATH TO YOUR UNITY EDITOR EXECUTABLE HERE
# Examples:
# UNITY_EDITOR_PATH="C:/Program Files/Unity/Hub/Editor/2022.3.10f1/Editor/Unity.exe" # Windows with Hub
# UNITY_EDITOR_PATH="/Applications/Unity/Hub/Editor/2022.3.10f1/Unity.app/Contents/MacOS/Unity" # macOS with Hub
# UNITY_EDITOR_PATH="/opt/Unity/Hub/Editor/2022.3.10f1/Editor/Unity" # Linux with Hub
UNITY_EDITOR_PATH="/opt/unity/6000.0.50f1/Editor/Unity"
# --- Script Arguments ---
UNITY_USERNAME="$1"
UNITY_PASSWORD="$2"
# Optional: Path to the Unity project (defaults to current directory if not provided)
PROJECT_PATH="${3:-.}"
# Optional: Path for the build output (defaults to ./Builds/Windows/MyGame.exe if not provided)
BUILD_NAME="MyGame" # You can change the default game name here
BUILD_OUTPUT_DEFAULT="./Builds/Windows/${BUILD_NAME}.exe"
BUILD_OUTPUT_PATH="${4:-$BUILD_OUTPUT_DEFAULT}"

# --- Pre-flight Checks ---
if [ -z "$UNITY_EDITOR_PATH" ]; then
  echo "ERROR: UNITY_EDITOR_PATH is not set in the script."
  echo "Please edit unity_build.sh and set the correct path to your Unity Editor executable."
  exit 1
fi

if [ ! -f "$UNITY_EDITOR_PATH" ] && [ ! -x "$UNITY_EDITOR_PATH" ]; then
    # On macOS, the executable is inside the .app bundle, -f might not work as expected with the direct path
    # but -x should still work. For Windows/Linux, -f is a good check.
    # A more robust check might be needed depending on OS, but this covers common cases.
    if [[ "$OSTYPE" != "darwin"* || ! -d "${UNITY_EDITOR_PATH%/Contents/MacOS/Unity}" ]]; then
        echo "ERROR: Unity Editor not found or not executable at: $UNITY_EDITOR_PATH"
        echo "Please verify the UNITY_EDITOR_PATH in the script."
        exit 1
    fi
fi


if [ -z "$UNITY_USERNAME" ] || [ -z "$UNITY_PASSWORD" ]; then
  echo "Usage: $0 <username> <password> [project_path] [build_output_path]"
  echo "Example: $0 your_email@example.com YourPassword123 ./MyUnityProject ./Builds/MyGame.exe"
  echo ""
  echo "  <username>          : Your Unity ID username (email)."
  echo "  <password>          : Your Unity ID password."
  echo "  [project_path]      : (Optional) Path to the Unity project directory."
  echo "                        Defaults to the current directory ('.') if not provided."
  echo "  [build_output_path] : (Optional) Full path for the Windows build output (e.g., ./Builds/Windows/Game.exe)."
  echo "                        Defaults to '$BUILD_OUTPUT_DEFAULT' if not provided."
  exit 1
fi

PROJECT_PATH="$(cd "$PROJECT_PATH" && pwd)"

# For BUILD_OUTPUT_PATH, first get the directory part and filename
BUILD_OUTPUT_DIR_RAW="$(dirname "$BUILD_OUTPUT_PATH")"
BUILD_OUTPUT_FILENAME="$(basename "$BUILD_OUTPUT_PATH")"

# Ensure build output directory exists
mkdir -p "$BUILD_OUTPUT_DIR_RAW"
if [ $? -ne 0 ]; then
  echo "ERROR: Could not create build output directory: $BUILD_OUTPUT_DIR_RAW"
  exit 1
fi

# Now that the directory is created, resolve its absolute path
BUILD_OUTPUT_DIR_ABS="$(cd "$BUILD_OUTPUT_DIR_RAW" && pwd)"
BUILD_OUTPUT_PATH_ABS="${BUILD_OUTPUT_DIR_ABS}/${BUILD_OUTPUT_FILENAME}"

# Ensure build output directory exists (this check is now redundant if the above mkdir succeeded, but harmless)
# mkdir -p "$BUILD_OUTPUT_DIR_ABS"
# if [ $? -ne 0 ]; then
#   echo "ERROR: Could not create build output directory: $BUILD_OUTPUT_DIR_ABS"
#   exit 1
# fi

LOG_FILE_PATH="${PROJECT_PATH}/unity_build_$(date +%Y%m%d_%H%M%S).log"


# --- Build Command ---
echo "--------------------------------------------------"
echo "Starting Unity Windows (64-bit) Build..."
echo "--------------------------------------------------"
echo "Unity Editor:      $UNITY_EDITOR_PATH"
echo "Project Path:      $PROJECT_PATH"
echo "Output Path:       $BUILD_OUTPUT_PATH_ABS"
echo "Username:          $UNITY_USERNAME"
echo "Log File:          $LOG_FILE_PATH"
echo "--------------------------------------------------"

# Execute Unity Build
# -quit: Quits the Unity Editor after the command is executed.
# -batchmode: Runs Unity in non-interactive mode.
# -nographics: Prevents Unity from initializing the graphics device (useful for headless buiads).
# -username & -password: For Unity login.
# -projectPath: Specifies the project to open/build.
# -buildWindows64Player: Builds a standalone 64-bit Windows player to the specified path.
# -logFile: Specifies where to write the editor log.
"$UNITY_EDITOR_PATH" \
  -quit \
  -batchmode \
  -nographics \
  -username "$UNITY_USERNAME" \
  -password "$UNITY_PASSWORD" \
  -projectPath "$PROJECT_PATH" \
  -buildWindows64Player "$BUILD_OUTPUT_PATH_ABS" \
  -logFile "$LOG_FILE_PATH"

UNITY_EXIT_CODE=$?

# --- Post Build ---
echo "--------------------------------------------------"
if [ $UNITY_EXIT_CODE -eq 0 ]; then
  echo "Build SUCCESSFUL!"
  echo "Output at: $BUILD_OUTPUT_PATH_ABS"
  echo "Log file: $LOG_FILE_PATH"
  echo "--------------------------------------------------"
  exit 0
else
  echo "Build FAILED with exit code $UNITY_EXIT_CODE."
  echo "Please check the log file for details: $LOG_FILE_PATH"
  echo "Common issues:"
  echo "  - Incorrect Unity Editor path."
  echo "  - Incorrect username/password or licensing issues."
  echo "  - Build script errors within the Unity project."
  echo "  - Insufficient disk space or permissions for the output path."
  echo "--------------------------------------------------"
  exit $UNITY_EXIT_CODE
fi