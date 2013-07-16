#!/usr/bin/env bash

# TODO: Use GitHub API and fork mxcl/homebrew?
set -o nounset

source ./utils.sh

MAIN_REPO="https://github.com/JamieMason/ImageOptim-CLI.git"
## TODO - no hardcoding
USER="jamesstout"

#set -e

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
	e_error "NOT a git repo, cd to your clone of ImageOptim-CLI: $MAIN_REPO"
	exit 1
fi

if (! is_main_git_repo "$MAIN_REPO" ); then
	e_error "NOT main repo remote - forked  - Aborting."
	exit 1
fi

if (! is_master_branch ); then
	e_error "NOT master branch. Please switch to master - Aborting."
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

# brew update ??

# Edit formula
echo "Getting homepage from Formula"
HOMEPAGE=$(grep head $FORMULA_PATH | awk '{ print $2 }' | sed "s/'//g")
e_success "HOMEPAGE = $HOMEPAGE"

echo "Getting latest version from GitHub"
# TODO: error check
LATEST_VERSION=$(git describe --tags $(git rev-list --tags --max-count=1))
e_success "LATEST_VERSION = $LATEST_VERSION"

# remove the .git extension
HOMEPAGE=${HOMEPAGE/%.git/}
ARCHIVE_URL=$HOMEPAGE/archive/$LATEST_VERSION.tar.gz

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
# TODO: error check
sed -i '' "s/^  url.*$/  url '$ESCAPED_ARCHIVE_URL'/" $FORMULA_PATH
e_success "Formula file url updated to $ARCHIVE_URL"

FILE=/tmp/$FORMULA-$LATEST_VERSION.tar.gz
echo "Download $ARCHIVE_URL to $FILE"
## TODO: which curl and error check
#curl  -L -o $FILE $ARCHIVE_URL

get_url "$ARCHIVE_URL" "$FILE"
#curl  -L -o $FILE $ARCHIVE_URL
e_success "Download complete"

echo "Get shasum of $FILE"
## TODO: which shasum and error check
SHASUM=$(shasum $FILE | awk '{ print $1 }')
e_success "New sha1 = $SHASUM"

rm $FILE
echo "Edit sha1 in Formula file"
# TODO: error check
sed -i '' "s/^  sha1.*$/  sha1 '$SHASUM'/" $FORMULA_PATH
e_header "SUCCESS"

e_warning "New Formula file is:"
cat "$FORMULA_PATH"

e_warning "Now check in to your fork of https://github.com/mxcl/homebrew and push"
e_warning "Then go to https://github.com/$USER/homebrew/pull/new/$FORMULA"
exit;

## TODO - automate this bit

# Commit
#git ci -m "Update $FORMULA to $LATEST_VERSION" Library/Formula/$FORMULA.rb

# Push
#git push git@github.com:$USER/homebrew.git $FORMULA
