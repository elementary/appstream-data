#!/bin/bash
set -e

apt-get update
apt-get install -y git

# if a custom token is provided, use it instead of the default github token.
if [ -n "$GIT_USER_TOKEN" ]; then
  GITHUB_TOKEN="$GIT_USER_TOKEN"
fi

if [ -z "${GITHUB_TOKEN}" ]; then
  echo "\033[0;31mERROR: The GITHUB_TOKEN environment variable is not defined.\033[0m"  && exit 1
fi

# default email and username to github actions user
if [ -z "$GIT_USER_EMAIL" ]; then
  GIT_USER_EMAIL="action@github.com"
fi
if [ -z "$GIT_USER_NAME" ]; then
  GIT_USER_NAME="GitHub Action"
fi

cd /repo

git fetch
echo "Setting up git credentials..."
git remote set-url origin https://x-access-token:"$GITHUB_TOKEN"@github.com/"$GITHUB_REPOSITORY".git
git config --global user.email "$GIT_USER_EMAIL"
git config --global user.name "$GIT_USER_NAME"
echo "Git credentials configured."

# get old yml contents
OLD_CHANGES=$(find diff/main/ -type f -name "*.yml.gz")
UNZIPPED_OLD_CHANGES="${OLD_CHANGES%.*}"
gunzip "$OLD_CHANGES"
sed -i.bak '/Time: /d' "$UNZIPPED_OLD_CHANGES"
# get new yml contents
NEW_CHANGES=$(find main/ -type f -name "*.yml.gz")
UNZIPPED_NEW_CHANGES="${NEW_CHANGES%.*}"
gunzip "$NEW_CHANGES"
sed -i.bak '/Time: /d' "$UNZIPPED_NEW_CHANGES"

# Check to see if there are changes to push
if ! diff "$UNZIPPED_OLD_CHANGES" "$UNZIPPED_NEW_CHANGES"; then
  # there are changes! Clean up, then push the new metadata
  rm -rf "$UNZIPPED_NEW_CHANGES"
  mv "$UNZIPPED_NEW_CHANGES".bak "$UNZIPPED_NEW_CHANGES"
  gzip "$UNZIPPED_NEW_CHANGES"
  echo "Pushing new metadata to repository"
  git checkout master
  git add .
  git commit -m "Automatic update of metadata"
  git push --set-upstream origin master
  echo "Push complete"
else
  echo "no changes present, nothing to push"
fi


