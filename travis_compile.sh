#!/bin/bash

SOURCE_BRANCH="master"
TARGET_BRANCH="package"

if [ "$TRAVIS_PULL_REQUEST" != "false" -o "$TRAVIS_BRANCH" != "$SOURCE_BRANCH" ]; then
    exit
fi

# Checkout target branch and create if it doesn't exists.
git checkout $TARGET_BRANCH || git checkout -b $TARGET_BRANCH --track origin $SOURCE_BRANCH || exit 0
git status
# Update to latest changes.
git pull --rebase

# Remove files that shouldn't be in composer.
cp native/owgen ./
rm -r native/* || exit 0
cp owgen native/

# Add git identity.
git config user.name "Travis CI"
git config user.email "$COMMIT_AUTHOR_EMAIL"

# Commit the changes and push to target branch.
git add -A
version=$(php -r "echo json_decode(file_get_contents('composer.json'))->extra->{'branch-alias'}->{'dev-package'};")
git commit -m "Compose $version"

chmod 600 compose_key
eval `ssh-agent -s`
ssh-add compose_key

git push origin $TARGET_BRANCH
