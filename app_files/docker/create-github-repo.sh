#!/usr/bin/env bash

set -e
# set -x

answered_yes() {
    echo -e "\n$1 [Yes] "
    read answer
    case $answer in
        [Nn]* ) return 1;;
        * ) return 0;;
    esac
}

if ! answered_yes "Create primary git repo in Github?"; then
    echo "Skipping creation of Github repo"
    exit 0
fi

APP_NAME=${PWD##*/}

echo -e "\nGithub repo name? [$APP_NAME] "
read REPO_NAME
if [[ -z "${REPO_NAME// }" ]]; then
    REPO_NAME=$APP_NAME
fi

if ! gh auth status; then
    gh auth login
fi

if gh repo view $REPO_NAME 1>/dev/null 2>/dev/null; then
    echo "Error: Github repo $REPO_NAME already exists"
    exit 1
fi

echo "Creating Github repo $REPO_NAME..."
if ! gh repo create $REPO_NAME --confirm --public; then
    echo "Could not create remote repo in Github "
    exit 1
fi

git push origin master
