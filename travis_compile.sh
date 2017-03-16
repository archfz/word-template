#!/bin/bash

SOURCE_BRANCH="master"
TARGET_BRANCH="package"

if [ "$TRAVIS_PULL_REQUEST" != "false" -o "$TRAVIS_BRANCH" != "$SOURCE_BRANCH" ]; then
    echo "No compose needed."
    exit
fi

# Add git identity.
git config user.name "Travis CI"
git config user.email "$COMMIT_AUTHOR_EMAIL"

# Move and protect key.
chmod 600 compose_key
mv compose_key ~/.ssh/id_rsa

REPO=`git config remote.origin.url`
SSH_REPO=${REPO/https:\/\/github.com\//git@github.com:}

# Checkout new branch.
echo "Checking out $TARGET_BRANCH."
git fetch origin
git checkout -b $TARGET_BRANCH --track origin/$SOURCE_BRANCH

# Remove files that shouldn't be in composer.
echo "Composing."
cp native/owgen ./
rm -r native/* || exit 0
mv owgen native/

git status
echo "Changes detected."

# Commit the changes and push to target branch.
git add -A
version=$(php -r "echo json_decode(file_get_contents('composer.json'))->extra->{'branch-alias'}->{'dev-package'};")
git commit -m "Compose $version"

# Force push as we won't be able to update otherwise.
echo "Pushing to origin $TARGET_BRANCH."
git push $SSH_REPO $TARGET_BRANCH --force
