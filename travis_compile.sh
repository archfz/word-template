#!/bin/bash

SOURCE_BRANCH="master"
TARGET_BRANCH="package"

if [ "$TRAVIS_PULL_REQUEST" != "false" -o "$TRAVIS_BRANCH" != "$SOURCE_BRANCH" ]; then
    echo "No compose needed."
    exit
fi

# Checkout target branch and create if it doesn't exists.
echo "Checking out $TARGET_BRANCH."
git checkout $TARGET_BRANCH || git checkout --orphan $TARGET_BRANCH || exit 0
git status
# Update to latest changes.
echo "Updating $TARGET_BRANCH."
git pull --rebase

# Remove files that shouldn't be in composer.
echo "Composing"
cp native/owgen ./
rm -r native/* || exit 0
cp owgen native/

diff=$(git diff origin ${TARGET_BRANCH})
if [ "$diff" == "" ]; then
    echo "Nothing changed. Exiting composition."
    exit 0
fi

echo "Changes detected."

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

echo "Pushing to origin $TARGET_BRANCH."
git push origin $TARGET_BRANCH
