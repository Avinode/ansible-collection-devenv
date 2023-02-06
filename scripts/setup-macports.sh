#! /bin/bash

#set -o xtrace
set -o errexit
set -o pipefail
set -o nounset

DISABLE_SPOTLIGHT="false"
while true; do
  case "${1:-}" in
    --stop-spotlight )
      DISABLE_SPOTLIGHT="true"
      shift 1
      ;;
    * ) break ;;
  esac
done

#------------------------------------------------------------------------------
# Helper functions
#------------------------------------------------------------------------------
function log() {
  echo -e "\n+" "$@"
}

function get_latest_macports_version() {
  local _auth_header
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    _auth_header=(--header "authorization: Bearer $GITHUB_TOKEN")
  fi
  /usr/bin/curl \
      --fail --silent "${_auth_header[@]}" \
      --header 'Accept: application/vnd.github.v3+json' \
      'https://api.github.com/repos/macports/macports-base/releases/latest' \
    | /usr/bin/python3 -c "import sys, json; print(json.load(sys.stdin)['tag_name'])" \
    | /usr/bin/sed -e 's/^v//'
}

function get_macos_version() {
  local _version
  local _version_parts
  _version=$(/usr/bin/sw_vers -productVersion)
  IFS='.' read -r -a _version_parts <<< "$_version"
  if [[ "${_version_parts[0]}" -lt 11 ]]; then
    echo "${_version_parts[0]}.${_version_parts[1]}"
  else
    echo "${_version_parts[0]}"
  fi
}

function get_macos_friendly_name() {
  # Thank you: https://apple.stackexchange.com/a/333470
  /usr/bin/awk \
      '/SOFTWARE LICENSE AGREEMENT FOR macOS/' \
      '/System/Library/CoreServices/Setup Assistant.app/Contents/Resources/en.lproj/OSXSoftwareLicense.rtf' \
    | /usr/bin/awk -F 'macOS ' '{print $NF}' \
    | /usr/bin/awk '{print substr($0, 0, length($0)-1)}' \
    | /usr/bin/tr -d '[:space:]'

}

function get_macports_pkg_file_name() {
  echo "MacPorts-$MACPORTS_VERSION-$(get_macos_version)-$(get_macos_friendly_name).pkg"
}


#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------
if [ "${DISABLE_SPOTLIGHT}" == "true" ]; then
  log 'Disabeling Spotlight Search indexing'
  /usr/bin/sudo mdutil -a -i off
fi

log 'Installation information...'
MACPORTS_VERSION="$(get_latest_macports_version)"
MACPORTS_PKG_FILE="$(get_macports_pkg_file_name)"
MACPORTS_PKG_URL="https://github.com/macports/macports-base/releases/download/v$MACPORTS_VERSION/$MACPORTS_PKG_FILE"
echo MACPORTS_PKG_FILE="$MACPORTS_PKG_FILE"
echo MACPORTS_PKG_URL="$MACPORTS_PKG_URL"

log 'Downloading MacPorts...'
/usr/bin/curl \
    --fail \
    --location \
    --remote-name \
    --show-error \
    --silent \
    "$MACPORTS_PKG_URL"

if ! sudo -n true 2>/dev/null; then
  echo "======================================================="
  echo "== Asking for password in order to update Mac Ports ==="
  echo "======================================================="
fi

log 'Installing MacPorts...'
/usr/bin/sudo /usr/sbin/installer -pkg "$MACPORTS_PKG_FILE" -target /
rm "$MACPORTS_PKG_FILE"
export PATH="/opt/local/libexec/gnubin:/opt/local/bin:/opt/local/sbin:$PATH"
hash -r

log 'Running MacPorts selfupdate/upgrade...'
/usr/bin/sudo /opt/local/bin/port selfupdate
/usr/bin/sudo /opt/local/bin/port upgrade outdated

log 'Install minimum required MacPorts...'
/usr/bin/sudo /opt/local/bin/port -N install \
    coreutils \
    curl-ca-bundle \
    pip_select \
    py39-certifi \
    py39-distlib \
    py39-pip \
    py39-setuptools \
    py39-virtualenv \
    py39-wheel \
    python39 \
    python3_select \
    python_select

/usr/bin/sudo /opt/local/bin/port select python3 python39
/usr/bin/sudo /opt/local/bin/port select python python39
/usr/bin/sudo /opt/local/bin/port select pip3 pip39
/usr/bin/sudo /opt/local/bin/port select pip pip39
