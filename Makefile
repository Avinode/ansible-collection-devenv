BUILD_RAND_NAME ?= $(shell tr -dc a-z0-9 </dev/urandom | head -c 13)

IMAGE_DEBIAN11 := geerlingguy/docker-debian11-ansible:latest
IMAGE_DEBIAN11_PYTHON := '3.9'
IMAGE_UBUNTU2004 := geerlingguy/docker-ubuntu2004-ansible:latest
IMAGE_UBUNTU2004_PYTHON := '3.8'
IMAGE_UBUNTU2204 := geerlingguy/docker-ubuntu2204-ansible:latest
IMAGE_UBUNTU2204_PYTHON := 3.10

DEFAULT_IMAGE_NAME := DEBIAN11
IMAGE_DEFAULT := $(IMAGE_$(DEFAULT_IMAGE_NAME))
IMAGE_DEFAULT_PYTHON := $(IMAGE_$(DEFAULT_IMAGE_NAME)_PYTHON)

ANSIBLE_TEST_SANITY_EXCLUDES := \
		scripts/setup-local-ansible.sh \
		scripts/setup-macports.sh \
		.gitignore

integration_phony_targets := $(addprefix integration-, debian11 ubuntu2004 ubuntu2204)

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

# TODO - Add back once Ansible-core 2.15 is released:
#   - integration-ubuntu2004
#   - integration-ubuntu2204
# There have been cgroup changes in Ubuntu and others in Docker that are
# causing issues.  These should be resolved in Ansible-core 2.15.  Release
# schedule is in:
#   - https://docs.ansible.com/ansible/latest/reference_appendices/release_and_maintenance.html#ansible-core-release-cycle
# Changes seem to be in:
#   - https://github.com/ansible/ansible/commit/04fc98c794d425a42f83a062c163c981d8751512
integration: integration-debian11 # TODO - integration-ubuntu2004 integration-ubuntu2204

sanity:
	$(info $(SECTION))
	source .venv/bin/activate ; \
			ansible-test sanity --color \
					--docker $(IMAGE_DEBIAN11) \
					--python $(IMAGE_DEBIAN11_PYTHON) \
					--exclude scripts/setup-local-ansible.sh \
					--exclude scripts/setup-macports.sh \
					$(addprefix --exclude ,$(ANSIBLE_TEST_SANITY_EXCLUDES))

units:
	$(info $(SECTION))
	source .venv/bin/activate ; \
			ansible-test units --color \
					--docker $(IMAGE_DEBIAN11) \
					--python $(IMAGE_DEBIAN11_PYTHON)

$(integration_phony_targets):
	$(info $(SECTION))
	$(eval _NAME := $(shell echo $(@:integration-%=%) | tr '[:lower:]' '[:upper:]'))
	source .venv/bin/activate ; \
			ansible-test integration --color \
					--docker $(IMAGE_$(_NAME)) \
					--docker-privileged \
					--python $(IMAGE_$(_NAME)_PYTHON)

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
