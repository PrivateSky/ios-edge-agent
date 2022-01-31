#!/bin/bash

projDir=${PROJECT_DIR:-"./../"}
startingDir=$(pwd)

cd "$projDir"
pwd
echo "Begin fetching required dependencies"

title='Dependencies fetch error'
description='In order to properly compile the project please make sure that on the build machine the \"carthage\" utility is installed'

cmd='set titleText to '"\"$title\""'
set dialogText to '"\"$description\""'
display dialog dialogText with icon stop with title titleText'

showDialog() {
    /usr/bin/osascript -e "$cmd" &
}

printToConsole() {
    printf "%s\n%s" "$title" "$description"
}

ensureCommandExists() {
    if ! command -v "$1" &> /dev/null; then
        showDialog
        printToConsole
        exit 1
    fi
}

ensureCommandExists "carthage"

carthage update --use-xcframeworks --cache-builds

cd "$startingDir"

echo "Dependency fetch done"
