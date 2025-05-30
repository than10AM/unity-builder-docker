#!/bin/bash

# Configure Git with environment variables
if [ -n "$GIT_USERNAME" ] && [ -n "$GIT_EMAIL" ]; then
  echo "Configuring Git with user: $GIT_USERNAME"
  git config --global user.name "$GIT_USERNAME"
  git config --global user.email "$GIT_EMAIL"
fi

# Configure GitHub token if provided
if [ -n "$GIT_TOKEN" ]; then
  echo "Configuring Git token"
  # The /root/.git-credentials path is a directory due to the volume mount.
  # We'll create a file inside this directory to store credentials.
  CREDENTIALS_DIR="/root/.git-credentials"
  CREDENTIALS_FILE="$CREDENTIALS_DIR/store"

  # Ensure the directory exists (it should, as it's a volume mount)
  mkdir -p "$CREDENTIALS_DIR"

  # Configure git to use this specific file for storing credentials
  git config --global credential.helper "store --file=$CREDENTIALS_FILE"
  
  # Write the credentials to the specified file
  echo "https://$GIT_USERNAME:$GIT_TOKEN@github.com" > "$CREDENTIALS_FILE"
  chmod 600 "$CREDENTIALS_FILE"
fi

echo "Git authentication completed"