#!/bin/bash

# this is jank and ugly, I know
LAYOUT="$(defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleSelectedInputSources | grep "KeyboardLayout Name" | cut -c 33- | rev | cut -c 2- | rev)"

# specify short layouts individually.
case "$LAYOUT" in
    "\"U.S.\"") SHORT_LAYOUT="US";;
    "Danish") SHORT_LAYOUT="DK";;
    "ABC")      SHORT_LAYOUT="ANY" ;;
    *)          SHORT_LAYOUT="?" ;;

esac

sketchybar --set keyboard label="$SHORT_LAYOUT"
