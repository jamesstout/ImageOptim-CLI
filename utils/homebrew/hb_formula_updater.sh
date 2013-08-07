#!/usr/bin/env bash

# TODO: Use GitHub API and fork mxcl/homebrew?
set -o nounset

source ./utils.sh

MAIN_REPO="https://github.com/JamieMason/ImageOptim-CLI.git"

if [ $# -eq 0 ];
then
    e_header "Usage: $0 <formula name>"
    exit 0
fi

e_header "Updating Homebrew formula file with latest URL and sha1..."

if ! type_exists 'brew'; then
    printf "\n"
    e_error "Error: Homebrew not found."
    printf "Aborting...\n"
    exit 1
fi

if ! is_git_repo ; then
	e_error "NOT a git repo, cd to your clone/fork of ImageOptim-CLI: $MAIN_REPO"
	exit 1
fi

if ! is_main_git_repo "$MAIN_REPO"; then
    e_warning "NOT main git repo, checking if a fork"
    if ! is_forked_git_repo_with_upstream "$MAIN_REPO"; then
        e_error "Aborting."
        e_error "Not a clone or fork of ImageOptim-CLI: $MAIN_REPO"
        exit;
    else
        e_debug "it's a fork!"
        fork="upstream"
    fi
else
    e_debug "it's a clone - use origin"
fi

# if we get to here then its a clone or a fork, we need to fetch any new tags
# a fetch is safe I think
# so if $fork is set it fetches upstream, otherwise it's a clone, so fetch origin
e_debug "Fetching new tags"
git fetch --tags -v ${fork:-origin}
RC=$?
if [ $RC -ne 0 ] 
then
    e_error "Aborting. git fetch --tags failed"
    exit 1
fi

FORMULA=$1
FORMULA_PATH="`brew --prefix`/Library/Formula/$FORMULA.rb"

if [ ! -f $FORMULA_PATH ];
then
    e_error "$FORMULA_PATH not found!"
    exit 1
fi

e_success "FORMULA_PATH = $FORMULA_PATH"

echo "Getting latest tag from GitHub"

LATEST_VERSION=$(git describe --tags $(git rev-list --tags --max-count=1))
RC=$?

if [ $RC -ne 0 ] || [ ${#LATEST_VERSION} -eq 0 ] # second clause checks LATEST_VERSION len > 0
then
    e_error "Aborting. Getting latest git tag failed."
    exit 1
fi

e_success "LATEST_VERSION = $LATEST_VERSION"

# remove the .git extension
MAIN_REPO=${MAIN_REPO/%.git/}
ARCHIVE_URL=$MAIN_REPO/archive/$LATEST_VERSION.tar.gz

e_success "ARCHIVE_URL = $ARCHIVE_URL"

echo "Check URL exists"
check_url "$ARCHIVE_URL"
RC=$?
if [ $RC -ne 0 ] 
then
    e_error "Aborting."
    exit 1
fi

e_success "URL exists"

ESCAPED_ARCHIVE_URL=$(echo $ARCHIVE_URL | sed 's/\//\\\//g')
e_success "ESCAPED_ARCHIVE_URL = $ESCAPED_ARCHIVE_URL"

echo "Edit URL in Formula file"
sed -i '' "s/^  url.*$/  url '$ESCAPED_ARCHIVE_URL'/" $FORMULA_PATH
RC=$?

if [ $RC -ne 0 ] 
then
    e_error "Aborting. sed edit of url line in $FORMULA_PATH failed"
    exit 1
fi

e_success "Formula file url updated to $ARCHIVE_URL"

FILE=/tmp/$FORMULA-$LATEST_VERSION.tar.gz
echo "Download $ARCHIVE_URL to $FILE"
## TODO: which curl and error check

get_url "$ARCHIVE_URL" "$FILE"

RC=$?
if [ $RC -ne 0 ] 
then
    e_error "Aborting. Failed to download $ARCHIVE_URL."
    exit 1
fi

#curl  -L -o $FILE $ARCHIVE_URL
e_success "Download complete"

# check we have shasum installed
if type_exists 'shasum'; then
    SHACMD="shasum"
elif type_exists 'sha1sum' ; then
    SHACMD="sha1sum"
else
    e_error "Aborting. No way to determine SHA1 hash."
    e_warning "shasum should come with OS X. Please check your install: /usr/bin/shasum"
    e_warning "Alternatively install md5sha1sum via homebrew."
    exit 1
fi

# sometimes shasum is not executable!
if ! [ -x /usr/bin/shasum ]
then
    e_error "Aborting. /usr/bin/shasum is not executable"
    e_warning "fix with \`sudo chmod +x /usr/bin/shasum\`"
    exit 1
fi

echo "Get $SHACMD of $FILE"
## TODO: which shasum and error check
SHASUM=$($SHACMD $FILE | awk '{ print $1 }')
RC=$?
if [ $RC -ne 0 ] 
then
    e_error "Aborting. Failed to determine SHA1 hash"
    exit 1
fi

e_success "New sha1 = $SHASUM"

#rm $FILE
echo "Edit sha1 in Formula file"
# TODO: error check
sed -i '' "s/^  sha1.*$/  sha1 '$SHASUM'/" $FORMULA_PATH
RC=$?

if [ $RC -ne 0 ] 
then
    e_error "Aborting. sed edit of sha1 line in $FORMULA_PATH failed"
    exit 1
fi

e_header "SUCCESS"

e_warning "New Formula file is:"
cat "$FORMULA_PATH"

e_warning "Now check in to your fork of https://github.com/mxcl/homebrew and push"
e_warning "Then go to https://github.com/USER/homebrew/pull/new/$FORMULA"
exit;

## TODO - automate this bit

# Commit
#git ci -m "Update $FORMULA to $LATEST_VERSION" Library/Formula/$FORMULA.rb

# Push
#git push git@github.com:$USER/homebrew.git $FORMULA
