#!/bin/bash

TARGET_BRANCH="master"

if [ "$TRAVIS_PULL_REQUEST" != "false" -o "$TRAVIS_BRANCH" != "$TARGET_BRANCH" ]; then
    echo "No compose needed."
    exit
fi

# Move and protect key.
chmod 600 compose_key
mv compose_key ~/.ssh/id_rsa

REPO=`git config remote.origin.url`
SSH_REPO=${REPO/https:\/\/github.com\//git@github.com:}

# Checkout target branch and create if it doesn't exists.
echo "Checking out $TARGET_BRANCH."
git remote set-branches --add origin $TARGET_BRANCH
git fetch origin
git checkout -b $TARGET_BRANCH origin/$TARGET_BRANCH

# Update to latest changes.
echo "Updating $TARGET_BRANCH."
git pull --rebase

# Remove files that shouldn't be in composer.
echo "Composing."
cp native/owgen ./
rm -r native/* || exit 0
mv owgen native/

diff=$(git diff origin ${TARGET_BRANCH})
if [ "$diff" == "" ]; then
    echo "Nothing changed. Exiting composition."
    exit 0
fi

git status
echo "Changes detected."

# Add git identity.
git config user.name "Travis CI"
git config user.email "$COMMIT_AUTHOR_EMAIL"

# Commit the changes and push to target branch.
git add -A
version=$(php -r "echo json_decode(file_get_contents('composer.json'))->extra->{'branch-alias'}->{'dev-package'};")
git commit -m "Travis CI compose $version"

echo "Pushing to origin $TARGET_BRANCH."
git push $SSH_REPO $TARGET_BRANCH
