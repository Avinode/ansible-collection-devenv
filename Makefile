BUILD_RAND_NAME ?= $(shell tr -dc a-z0-9 </dev/urandom | head -c 13)

IMAGE_DEBIAN11 := geerlingguy/docker-debian11-ansible:latest
IMAGE_DEBIAN11_PYTHON := '3.9'
IMAGE_DEBIAN12 := geerlingguy/docker-debian12-ansible:latest
IMAGE_DEBIAN12_PYTHON := '3.11'

# The following Ubuntu images are from:
# 	- https://github.com/ansible/ansible/blob/devel/test/lib/ansible_test/_data/completion/docker.txt
IMAGE_UBUNTU2004 := ubuntu2004
IMAGE_UBUNTU2004_PYTHON := '3.8'
IMAGE_UBUNTU2204 := ubuntu2204
IMAGE_UBUNTU2204_PYTHON := 3.10

DEFAULT_IMAGE_NAME := DEBIAN11
IMAGE_DEFAULT := $(IMAGE_$(DEFAULT_IMAGE_NAME))
IMAGE_DEFAULT_PYTHON := $(IMAGE_$(DEFAULT_IMAGE_NAME)_PYTHON)

integration_phony_targets := $(addprefix integration-, debian11 debian12 ubuntu2004 ubuntu2204)

.PHONY: \
		$(integration_phony_targets) \
		integration \
		sanity \
		super-linter \
		units


#------------------------------------------------------------------------------
# Targets
#------------------------------------------------------------------------------
all: pre-commit

pre-commit: super-linter sanity units integration

# integration: integration-debian11 integration-ubuntu2004 integration-ubuntu2204 integration-debian12  # TODO - Get these working again

$(integration_phony_targets):
	$(info $(SECTION))
	$(eval _NAME := $(shell echo $(@:integration-%=%) | tr '[:lower:]' '[:upper:]'))
	source .venv/bin/activate ; \
			ansible-test integration --color \
					--docker $(IMAGE_$(_NAME)) \
					--docker-privileged \
					--python $(IMAGE_$(_NAME)_PYTHON)

integration:
	$(info $(SECTION))
	source .venv/bin/activate ; \
			ansible-test integration --color --docker ubuntu2204

sanity:
	$(info $(SECTION))
	source .venv/bin/activate ; \
			ansible-test sanity --color --docker \
					--exclude .gitignore \
					--exclude scripts/setup-local-ansible.sh \
					--exclude scripts/setup-macports.sh

units:
	$(info $(SECTION))
	source .venv/bin/activate ; \
			ansible-test units --color --docker

super-linter:
	$(info $(SECTION))
	# TODO - Turn `GITHUB_ACTIONS` back on once it is working again.
	docker run \
			--rm \
			--env RUN_LOCAL=true \
			--env PYTHONPATH=/tmp/lint/.venv/lib/python3.8/site-packages \
			--env VALIDATE_GITHUB_ACTIONS=false \
			--volume $$PWD:/tmp/lint \
			--name ansible-playbooks-avinode-super-linter-$(BUILD_RAND_NAME) \
			github/super-linter:slim-v4


#------------------------------------------------------------------------------
# Other
#------------------------------------------------------------------------------
define SECTION

===============================================================================
= Processing: $@
===============================================================================
endef
