#!/bin/bash
set -ex # Exit immediately if a command exits with a non-zero status, and print commands.

# --- !!! IMPORTANT CONFIGURATION !!! ---
# SET THE PATH TO YOUR UNITY EDITOR EXECUTABLE HERE
# Examples:
# UNITY_EDITOR_PATH="C:/Program Files/Unity/Hub/Editor/2022.3.10f1/Editor/Unity.exe" # Windows with Hub
# UNITY_EDITOR_PATH="/Applications/Unity/Hub/Editor/2022.3.10f1/Unity.app/Contents/MacOS/Unity" # macOS with Hub
# UNITY_EDITOR_PATH="/opt/Unity/Hub/Editor/2022.3.10f1/Editor/Unity" # Linux with Hub
UNITY_EDITOR_PATH="/opt/unity/6000.0.49f1/Editor/Unity"

echo "--- Script Arguments ---"
echo "Arg 1 (UNITY_USERNAME): '$1'"
echo "Arg 2 (UNITY_PASSWORD): '$2'"
echo "Arg 3 (PROJECT_PATH input): '$3'"
echo "Arg 4 (BUILD_OUTPUT_PATH input): '$4'"
echo "------------------------"

# --- Script Arguments ---
UNITY_USERNAME="$1"
UNITY_PASSWORD="$2"
# Optional: Path to the Unity project (defaults to current directory if not provided)
PROJECT_PATH_ARG="${3:-.}"
# Optional: Path for the build output
BUILD_OUTPUT_PATH_ARG="${4}"

# --- Pre-flight Checks ---
if [ -z "$UNITY_EDITOR_PATH" ]; then
  echo "ERROR: UNITY_EDITOR_PATH is not set in the script."
  echo "Please edit unity_build.sh and set the correct path to your Unity Editor executable."
  exit 1
fi

if [ ! -f "$UNITY_EDITOR_PATH" ] && [ ! -x "$UNITY_EDITOR_PATH" ]; then
    if [[ "$OSTYPE" != "darwin"* || ! -d "${UNITY_EDITOR_PATH%/Contents/MacOS/Unity}" ]]; then
        echo "ERROR: Unity Editor not found or not executable at: $UNITY_EDITOR_PATH"
        echo "Please verify the UNITY_EDITOR_PATH in the script."
        exit 1
    fi
fi

if [ -z "$UNITY_USERNAME" ] || [ -z "$UNITY_PASSWORD" ]; then
  echo "Usage: $0 <username> <password> [project_path] [build_output_path]"
  # ... (rest of usage message)
  exit 1
fi

echo "--- Path Resolutions ---"
echo "PROJECT_PATH_ARG: '$PROJECT_PATH_ARG'"
PROJECT_PATH="$(cd "$PROJECT_PATH_ARG" && pwd)"
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to resolve project path from: '$PROJECT_PATH_ARG'"
  exit 1
fi
echo "Resolved PROJECT_PATH: '$PROJECT_PATH'"

BUILD_NAME="MyGame" # You can change the default game name here
# Default build output path is now constructed using the resolved absolute PROJECT_PATH
BUILD_OUTPUT_DEFAULT="${PROJECT_PATH}/Builds/Windows/${BUILD_NAME}.exe"

# Determine BUILD_OUTPUT_PATH
if [ -n "$BUILD_OUTPUT_PATH_ARG" ]; then
    BUILD_OUTPUT_PATH="$BUILD_OUTPUT_PATH_ARG"
    echo "Using provided BUILD_OUTPUT_PATH_ARG: '$BUILD_OUTPUT_PATH'"
else
    BUILD_OUTPUT_PATH="$BUILD_OUTPUT_DEFAULT"
    echo "Using default BUILD_OUTPUT_PATH: '$BUILD_OUTPUT_PATH'"
fi
echo "Final BUILD_OUTPUT_PATH for dirname/basename: '$BUILD_OUTPUT_PATH'"

# For BUILD_OUTPUT_PATH, first get the directory part and filename
echo "DEBUG: which dirname: $(which dirname)"
echo "DEBUG: type dirname: $(type dirname)"
echo "DEBUG: Executing: dirname \"$BUILD_OUTPUT_PATH\""
BUILD_OUTPUT_DIR_RAW="$(dirname "$BUILD_OUTPUT_PATH")"
echo "DEBUG: dirname output (BUILD_OUTPUT_DIR_RAW): '$BUILD_OUTPUT_DIR_RAW'"

echo "DEBUG: Executing: basename \"$BUILD_OUTPUT_PATH\""
BUILD_OUTPUT_FILENAME="$(basename "$BUILD_OUTPUT_PATH")"
echo "DEBUG: basename output (BUILD_OUTPUT_FILENAME): '$BUILD_OUTPUT_FILENAME'"

if [ -z "$BUILD_OUTPUT_DIR_RAW" ]; then
    echo "ERROR: BUILD_OUTPUT_DIR_RAW is empty after dirname. This is unexpected."
    echo "       BUILD_OUTPUT_PATH was: '$BUILD_OUTPUT_PATH'"
    exit 1
fi

# Ensure build output directory exists
echo "Ensuring build output directory exists: '$BUILD_OUTPUT_DIR_RAW'"
mkdir -p "$BUILD_OUTPUT_DIR_RAW"
MKDIR_EXIT_CODE=$?
echo "mkdir -p exit code: $MKDIR_EXIT_CODE"

if [ $MKDIR_EXIT_CODE -ne 0 ]; then
  echo "ERROR: Could not create build output directory: '$BUILD_OUTPUT_DIR_RAW'"
  echo "Listing parent of target directory:"
  ls -ld "$(dirname "$BUILD_OUTPUT_DIR_RAW")" || echo "Could not list parent of $BUILD_OUTPUT_DIR_RAW"
  echo "Listing project path:"
  ls -ld "$PROJECT_PATH" || echo "Could not list $PROJECT_PATH"
  exit 1
fi
echo "Build output directory should now exist. Verifying: '$BUILD_OUTPUT_DIR_RAW'"
ls -ld "$BUILD_OUTPUT_DIR_RAW"

# Now that the directory is created, resolve its absolute path
echo "Resolving absolute path for BUILD_OUTPUT_DIR_RAW: '$BUILD_OUTPUT_DIR_RAW'"
BUILD_OUTPUT_DIR_ABS="$(cd "$BUILD_OUTPUT_DIR_RAW" && pwd)"
CD_PWD_EXIT_CODE=$?
echo "cd and pwd exit code for BUILD_OUTPUT_DIR_RAW: $CD_PWD_EXIT_CODE"

if [ $CD_PWD_EXIT_CODE -ne 0 ]; then
    echo "ERROR: Failed to cd into or pwd build output directory: '$BUILD_OUTPUT_DIR_RAW'"
    exit 1
fi
echo "Absolute BUILD_OUTPUT_DIR_ABS: '$BUILD_OUTPUT_DIR_ABS'"

BUILD_OUTPUT_PATH_ABS="${BUILD_OUTPUT_DIR_ABS}/${BUILD_OUTPUT_FILENAME}"
echo 'Final absolute BUILD_OUTPUT_PATH_ABS for Unity: '\''$BUILD_OUTPUT_PATH_ABS'\'''

# --- Unity Build Execution ---
# Use a fixed log file name for easier access
LOG_FILE_PATH="/project_data/unity_build.log"
rm -f "$LOG_FILE_PATH" # Remove old log file if it exists

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