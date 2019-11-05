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

echo "Pushing new metadata to repository"
git checkout master
git add .
git commit -m "Automatic update of metadata"
git push --set-upstream origin master
echo "Push complete"
