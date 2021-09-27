#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd )"
PROJECT_COLLECTION_DIR=$(realpath "$PROJECT_DIR/../..")


#------------------------------------------------------------------------------
# Helpers
#------------------------------------------------------------------------------
log_section() {
  (
    set +o xtrace
    echo
    echo "+------------------------------------------------------------------------------"
    echo "+ $*"
    echo "+------------------------------------------------------------------------------"
  )
}


#------------------------------------------------------------------------------
# Sanity checks
#------------------------------------------------------------------------------
log_section "Sanity checks"
echo "+ INFO - Setting up the project in: $PROJECT_DIR"
if [ -e "${PROJECT_DIR}/.venv" ]; then
  echo "+ ERROR - Already exists: ${PROJECT_DIR}/.venv"
  exit 1
fi

echo "+ INFO - Ansible collections are in: $PROJECT_COLLECTION_DIR"
_expected_project_collection_dir=$(realpath "$PROJECT_COLLECTION_DIR/..")/ansible_collections
if [ "$PROJECT_COLLECTION_DIR" != "$_expected_project_collection_dir" ]; then
  echo "+ ERROR - Parent directory must '$_expected_project_collection_dir', not: $PROJECT_COLLECTION_DIR"
  exit 1
fi

set -o xtrace


#------------------------------------------------------------------------------
# Install Python virtual env
#------------------------------------------------------------------------------
log_section "Setup Python virtual environment"
/usr/bin/python3 -m venv "${PROJECT_DIR}/.venv"
# shellcheck disable=SC1091
source "${PROJECT_DIR}/.venv/bin/activate"
pip3 install --upgrade --upgrade-strategy eager wheel pip
pip3 install ansible ansible-lint flake8 junit-xml mypi pylint pyright yamllint


#------------------------------------------------------------------------------
# Display setup
#------------------------------------------------------------------------------
log_section "Show configuration"
which ansible ansible-galaxy ansible-lint yamllint
ansible --version
ansible-galaxy --version
ansible-lint --version
yamllint --version


#------------------------------------------------------------------------------
# Install Ansible collections
#------------------------------------------------------------------------------
log_section "Install Ansible collections"
# shellcheck disable=SC2016
ruby -r yaml -r json -e 'puts YAML.load($stdin.read).to_json' < "${PROJECT_DIR}/galaxy.yml" \
    | jq -r '.dependencies | keys | .[]' \
    | xargs -I '{}' ansible-galaxy collection install --force --upgrade \
        --collections-path "$PROJECT_COLLECTION_DIR" '{}'
