#!/bin/bash

#set -o xtrace
set -o errexit
set -o pipefail
set -o nounset


#------------------------------------------------------------------------------
# Helper functions
#------------------------------------------------------------------------------
function log() {
  echo -e "\n+" "$@"
}

function get_latest_macports_version() {
  /usr/bin/curl \
      --fail --silent \
      --header 'Accept: application/vnd.github.v3+json' \
      --header "authorization: Bearer $GITHUB_TOKEN" \
      'https://api.github.com/repos/macports/macports-base/releases/latest' \
    | /usr/local/bin/jq --raw-output '.tag_name' \
    | /usr/bin/sed -e 's/^v//'
}

function get_macos_version() {
  /usr/bin/sw_vers -productVersion | /usr/bin/sed -E 's/\.[0-9]+$//'
}

function get_macos_friendly_name() {
  # Thank you: https://apple.stackexchange.com/a/333470
  /usr/bin/awk \
      '/SOFTWARE LICENSE AGREEMENT FOR macOS/' \
      '/System/Library/CoreServices/Setup Assistant.app/Contents/Resources/en.lproj/OSXSoftwareLicense.rtf' \
    | /usr/bin/awk -F 'macOS ' '{print $NF}' \
    | /usr/bin/awk '{print substr($0, 0, length($0)-1)}'
}

function get_macports_pkg_file_name() {
  echo "MacPorts-$(get_latest_macports_version)-$(get_macos_version)-$(get_macos_friendly_name).pkg"
}


#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------
log 'Disabeling Spotlight Search indexing'
/usr/bin/sudo mdutil -a -i off

log 'Installation information...'
MACPORTS_PKG_FILE="$(get_macports_pkg_file_name)"
echo MACPORTS_PKG_FILE="$MACPORTS_PKG_FILE"

log 'Downloading MacPorts...'
/usr/bin/curl \
    --fail \
    --location \
    --remote-name \
    --show-error \
    --silent \
    "https://distfiles.macports.org/MacPorts/$MACPORTS_PKG_FILE"

log 'Installing MacPorts...'
/usr/bin/sudo /usr/sbin/installer -pkg "$MACPORTS_PKG_FILE" -target /
export PATH="/opt/local/libexec/gnubin:/opt/local/bin:/opt/local/sbin:$PATH"
hash -r

log 'Running MacPorts selfupdate/upgrade...'
/usr/bin/sudo /opt/local/bin/port selfupdate
/usr/bin/sudo /opt/local/bin/port upgrade outdated

log 'Install minimum required MacPorts...'
/usr/bin/sudo /opt/local/bin/port install coreutils
