#!/usr/bin/env bash

# Header logging
e_header() {
    printf "\n$(tput setaf 7)%s$(tput sgr0)\n" "$@"
}
# debug logging
e_debug() {
    printf "$(tput setaf 2)%s$(tput sgr0)\n" "$@"
}

# Success logging
e_success() {
    printf "$(tput setaf 64)✓ %s$(tput sgr0)\n" "$@"
}

# Error logging
e_error() {
    printf "$(tput setaf 1)x %s$(tput sgr0)\n" "$@"
}

# Warning logging
e_warning() {
    printf "$(tput setaf 136)! %s$(tput sgr0)\n" "$@"
}

# Ask for confirmation before proceeding
seek_confirmation() {
    printf "\n"
    e_warning "$@"
    read -p "Continue? (y/n) " -n 1
    printf "\n"
}

# Test whether the result of an 'ask' is a confirmation
is_confirmed() {
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
      return 0
    fi
    return 1
}

type_exists() {
    if [ $(type -P $1) ]; then
      return 0
    fi
    return 1
}

dir_exists() {
    if [ -d "$1" ]; then
      return 0
    fi
    return 1
}

file_exists() {
    if [ -e "$1" ]; then
      return 0
    fi
    return 1
}

is_git_repo() {
    $(git rev-parse --is-inside-work-tree &> /dev/null)
}

get_git_branch() {
    local branch_name

    # Get the short symbolic ref
    branch_name=$(git symbolic-ref --quiet --short HEAD 2> /dev/null) ||
    # If HEAD isn't a symbolic ref, get the short SHA
    branch_name=$(git rev-parse --short HEAD 2> /dev/null) ||
    # Otherwise, just give up
    branch_name="(unknown)"

    printf $branch_name
}

is_master_branch(){
    local branch=$(get_git_branch)

    if [ "$branch" = "master" ]; then
        return 0
    fi
    
    return 1
}

is_main_git_repo() {

    local main_git_repo="$1"
    local remote_origin_url=$(git config --get remote.origin.url)

    if [[ "$remote_origin_url" == "$main_git_repo"* ]]; then
        return 0
    else
        return 1
    fi
}

# check check to see if the URl exists
# retCodes:
# 99 - missing param
# 88 - problem with URL
# 0 - all good
function check_url(){

    if [ $# -eq 0 ]
    then
        e_error "URL param required"

        return 99
    fi

    url="$1"

    # curl comes with OS X right?
    # curl params: fsLI 
    # f = Fail silently
    # s = Silent or quiet mode
    # L = Follow redirects
    # I = Fetch the HTTP-header only - we just want to see the url exists

    if type_exists "curl"; then
        #e_debug "using curl"

        curl -fsLI -o "/dev/null" "$url"

        RC=$?

        if [ $RC -ne 0 ] 
        then
            OUTPUT="$url Unavailable, please check"
            e_error "$OUTPUT"
            #echo "ERROR $OUTPUT"
            return 1

        else
            return 0
        fi
    elif type_exists "cURL"; then
        #e_debug "using cURL"
        cURL -fsLI -o "/dev/null" "$url"

        RC=$?

        if [ $RC -ne 0 ] ; then
            OUTPUT="$url Unavailable, please check"
            e_error "$OUTPUT"
            #echo "ERROR $OUTPUT"
            return 1
        else
            return 0
        fi
    elif type_exists "wget"; then # not sure wget comes as standard but we'll try it anyway: -q = quiet, -S headers only
        #e_debug "using wget";
        wget -S -q "$url" 2>/dev/null
        RC=$?

        if [ $RC -ne 0 ] ; then
            OUTPUT="$url Unavailable, please check"
            e_error "$OUTPUT"
            #echo "ERROR $OUTPUT"
            return 1
        else
            return 0
        fi       
    fi

}

# code dupe... needs more error checking

# retCodes:
# 99 - missing param
# 88 - problem with URL
# 0 - all good
function get_url(){

    if [ $# -eq 0 ] || [ $# -ne 2 ]
    then
        e_error "URL and FILE params required"

        return 99
    fi

    url="$1"
    file="$2"

    # curl comes with OS X right?
    # curl params: sL
    # f = Fail silently -- nooo
    # s = Silent or quiet mode
    # L = Follow redirects

    if type_exists "curl"; then
        e_debug "using curl"

        curl -sL -o "$file" "$url"

        RC=$?

        if [ $RC -ne 0 ] 
        then
            OUTPUT="$url Unavailable, please check"
            e_error "$OUTPUT"
            #echo "ERROR $OUTPUT"
            return 1

        else
            return 0
        fi
    elif type_exists "cURL"; then
        e_debug "using cURL"
        cURL -sL -o "$file" "$url"

        RC=$?

        if [ $RC -ne 0 ] ; then
            OUTPUT="$url Unavailable, please check"
            e_error "$OUTPUT"
            #echo "ERROR $OUTPUT"
            return 1
        else
            return 0
        fi
    elif type_exists "wget"; then # not sure wget comes as standard but we'll try it anyway: -q = quiet, -S headers only
        e_debug "using wget";
        wget -O "$file" "$url"
        RC=$?

        if [ $RC -ne 0 ] ; then
            OUTPUT="$url Unavailable, please check"
            e_error "$OUTPUT"
            #echo "ERROR $OUTPUT"
            return 1
        else
            return 0
        fi       
    fi

}