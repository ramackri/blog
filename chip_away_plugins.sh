#!/bin/bash

# foo
RESTORE='\033[0m'

RED='\033[00;31m'
GREEN='\033[00;32m'
YELLOW='\033[00;33m'
BLUE='\033[00;34m'
PURPLE='\033[00;35m'
CYAN='\033[00;36m'
LIGHTGRAY='\033[00;37m'

chip_away_at_plugins () {
    echo "stashing working directory changes..."
    STASH_MSG=$(git stash)
    for plugin in plugins/*; do
        echo "Trying out removing plugin ${plugin}..."

        # invalidate public diff so that failed generate will get caught
        echo "invalidate" >>public/index.html

        git rm ${plugin} >/dev/null
        ./build.sh &>/dev/null

        # remove XML timestamp stuff (not what we're interested in)
        find public -name *.xml | xargs -n 3 git checkout --

        DIFF=$(git diff)
        if [[ "$DIFF" != "" ]]; then
            echo -e "====> ${RED} There was a difference after removing the plugin ${plugin}!${RESTORE}"
            git reset HEAD ${plugin} >/dev/null
            git checkout -- ${plugin} public/ >/dev/null
        else
            echo -e "====> ${GREEN}Great success removing plugin ${plugin}!${RESTORE}"
        fi
    done
    echo "restoring working directory changes..."
    if [[ "$STASH_MSG" != "No local changes to save" ]]; then
        git stash pop >/dev/null
    fi
}

case "$1" in 
    apply)
        chip_away_at_plugins
        ;;
    rollback)
        git reset HEAD plugins/
        git checkout -- plugins
        git checkout -- public
        ;;
    *)
        echo "Usage: $0 {apply|rollback}"
        exit 1
esac
