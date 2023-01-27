#!/bin/bash

# Local history for Bash
# Version 1.2
# Use `lht help` for help and more information

# Copyright (c) 2023 Sqaaakoi
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.



# Prompt command magic
# This is NOT automatically injected; you must run this script with "--prompt-command" to inject it.
# This behaviour is intended so you can easily remove that argument from your .bashrc or similar so that you can override $PROMPT_COMMAND yourself.
# Please note that this must be injected to $PROMPT_COMMAND for this entire script to function correctly.
__localhistory_prompt_command() {
    # r/w history before running commands, helps with multiple shells
    history -a; history -n;
    $@
    __localhistory .
}

# Inject prompt command if "--prompt-command" is specified
if [ "$1" == "--prompt-command" ]; then
    __PROMPT_COMMAND() {
        __localhistory_prompt_command
        $@
    }
    export PROMPT_COMMAND="__PROMPT_COMMAND $PROMPT_COMMAND"
fi

# Local history per project
# Default history file
export __LOCALHISTORY_DEFAULT="$HISTFILE"
# File name for local history log
export __LOCALHISTORY_FILENAME=".local_bash_history"
# Current status of local history being enabled
export __LOCALHISTORY_ENABLED="true"
# Set to true if the local history has just been updated
export __LOCALHISTORY_RECENTLY_UPDATED="false"
# If the local history is active
export __LOCALHISTORY_ACTIVE="false"
# Find history file
__localhistory() {
    if [ "$__LOCALHISTORY_ENABLED" = "false" ]; then
        if [ "$__LOCALHISTORY_RECENTLY_UPDATED" = "true" ]; then
            __LOCALHISTORY_RECENTLY_UPDATED="false"
            HISTFILE="$__LOCALHISTORY_DEFAULT"
            return
        fi
    fi
    if [ "$__LOCALHISTORY_ENABLED" = "true" ]; then
        local __LOCALHISTORY_TRAVERSAL="$(__localhistory_realpath "$1")"
        # Is there a writable bash history file here?
        if [ -w "$(__localhistory_realpath "$__LOCALHISTORY_TRAVERSAL/$__LOCALHISTORY_FILENAME")" ]; then
            # Only set and display if new history file is found
            __localhistory_update "$__LOCALHISTORY_TRAVERSAL/$__LOCALHISTORY_FILENAME"
            export __LOCALHISTORY_ACTIVE="true"
        elif [ "$__LOCALHISTORY_TRAVERSAL" != "/" ]; then
            # Try traversing up to look again if we aren't already in root
            __localhistory "$__LOCALHISTORY_TRAVERSAL/.."
        else
            # Fallback to home directory
            __localhistory_update "$__LOCALHISTORY_DEFAULT"
            export __LOCALHISTORY_ACTIVE="false"
        fi
    fi
}
# Update the history file
__localhistory_update() {
    # $1 is the file
    if [ "$HISTFILE" != "$(__localhistory_realpath "$1")" ]; then
        # Write last history file
        history -a
        # Clear loaded history so history can be replaced
        history -c
        HISTFILE="$(__localhistory_realpath "$1")"
        export __LOCALHISTORY_RECENTLY_UPDATED="true"
        # Read history
        history -r;
    else
        export __LOCALHISTORY_RECENTLY_UPDATED="false"
    fi
}
# Used for paths with spaces in name
__localhistory_realpath() {
    realpath "$@"
}

# Local history management command
lht() {
    if [ "$1" = "status" ] || [ -z "$1" ]; then
        if [ "$__LOCALHISTORY_ENABLED" == "false" ]; then
            echo -e "\033[96mLocal history is \033[91mdisabled\033[00m"
            lht filename
            lht file
            return 2
        else
            if [ "$__LOCALHISTORY_ACTIVE" = "false" ]; then
                echo -e "\033[96mLocal history is \033[36minactive\033[00m"
                lht filename
                lht file
                return 1
            else 
                echo -e "\033[96mLocal history is \033[92mactive\033[00m"
                lht filename
                lht file
                return 0
            fi
        fi
    fi
    if [ "$1" = "filename" ]; then
        echo -e "\033[96mLocal history filename: \033[94m$__LOCALHISTORY_FILENAME\033[94m"
        return 0
    fi
    if [ "$1" = "file" ]; then
        echo -e "\033[96mHistory file: \033[94m$HISTFILE\033[00m"
        return 0
    fi
    if [ "$1" = "enable" ] || [ "$1" = "on" ]; then
        export __LOCALHISTORY_ENABLED="true"
        __localhistory .
        export __LOCALHISTORY_RECENTLY_UPDATED="false"
        echo -e "\033[92mEnabled\033[96m local history\033[00m"
        lht file
        return 0
    fi
    if [ "$1" = "disable" ] || [ "$1" = "off" ]; then
        export __LOCALHISTORY_ENABLED="false"
        export __LOCALHISTORY_ACTIVE="false"
        export __LOCALHISTORY_RECENTLY_UPDATED="true"
        echo -e "\033[91mDisabled\033[96m local history\033[00m"
        lht file
        return 0
    fi
    if [ "$1" = "create" ]; then
        touch "$__LOCALHISTORY_FILENAME"
        if [ "$2" = "git" ]; then
            echo -e "$__LOCALHISTORY_FILENAME" >> .gitignore
        fi
        __localhistory .
        lht file
        return 0
    fi
    if [ "$1" = "delete" ]; then
        if [ "$__LOCALHISTORY_ACTIVE" == "true" ]; then
            if [ "$HISTFILE" == "$__LOCALHISTORY_DEFAULT" ]; then 
                echo -e "\033[33mLocal history file seems to be the same as the default file; not deleting\033[00m"
                lht file
                return 2
            fi;
            history -c
            rm $HISTFILE
            HISTFILE="$__LOCALHISTORY_DEFAULT"
            __localhistory .
            lht file
            return 0
        fi;
        echo -e "\033[31mLocal history file doesn't exist\033[00m"
        lht file
        return 1
    fi
    if [ "$1" = "prompt_status" ]; then
        if [ "$__LOCALHISTORY_RECENTLY_UPDATED" = "true" ]; then
            echo -e "$5$HISTFILE$6"
            return 0
        fi
        if [ "$__LOCALHISTORY_ENABLED" = "true" ]; then
            if [ "$__LOCALHISTORY_ACTIVE" = "true" ]; then
                echo -e "$2"
                return 0
            fi
            echo -e "$3"
            return 0
        fi
        echo -e "$4"
        return 0
    fi
    if [ "$1" = "help" ]; then
        echo -e "\033[96mlht: Local History Tool\033[00m"
        echo -e ""
        echo -e "\033[94mRequired arguments are displayed as \033[32m[required]\033[00m"
        echo -e "\033[94mOptional / multi-choice arguments are displayed as \033[32m(option|alternate-option)\033[00m"
        echo -e ""
        echo -e "\033[36mlht\033[00m"
        echo -e "\033[36mlht status\033[00m"
        echo -e "\033[37m - Shows if local history is enabled, active, and the current history file\033[00m"
        echo -e "\033[36mlht filename\033[00m"
        echo -e "\033[37m - Shows the name of the local history file\033[00m"
        echo -e "\033[36mlht file\033[00m"
        echo -e "\033[37m - Shows the current history file\033[00m"
        echo -e "\033[36mlht enable\033[00m"
        echo -e "\033[36mlht on\033[00m"
        echo -e "\033[37m - Enables local history for this session\033[00m"
        echo -e "\033[36mlht disable\033[00m"
        echo -e "\033[36mlht off\033[00m"
        echo -e "\033[37m - Disables local history for this session\033[00m"
        echo -e "\033[36mlht create \033[32m(git|gitlocal)\033[00m"
        echo -e "\033[37m - Creates a local history file and optionally adds it to .gitignore (git) or .git/info/exclude (gitlocal)\033[00m"
        echo -e "\033[36mlht prompt_status \033[32m[active] [inactive] [disabled] [path_prefix] [path_suffix]\033[00m"
        echo -e "\033[37m - Shows [active] if enabled and active, [inactive] if local history is enabled and inactive, [disabled] if local history is disabled, and the new history file path surrounded by [path_prefix] and [path_suffix] if active and recently updated\033[00m"
        echo -e "\033[36mlht help\033[00m"
        echo -e "\033[36mlht --help\033[00m"
        echo -e "\033[37m - Shows this help message\033[00m"
        return 0
    fi

    echo -e "Unknown subcommand; run \"lht help\""
    return 4
}