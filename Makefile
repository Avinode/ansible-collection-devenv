IMAGE_DEBIAN10 := geerlingguy/docker-debian10-ansible:latest
IMAGE_DEBIAN10_PYTHON := 3.7
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

integration_phony_targets := $(addprefix integration-, debian10 debian11 ubuntu2004 ubuntu2204)

.PHONY: \
		$(integration_phony_targets) \
		integration \
		sanity \
		units


#------------------------------------------------------------------------------
# Targets
#------------------------------------------------------------------------------
all: pre-commit

pre-commit: sanity units integration

# TODO - Add the following once it works: integration-debian10 integration-ubuntu2204
integration: integration-debian11 integration-ubuntu2004

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
			--name ansible-playbooks-avinode-super-linter \
			github/super-linter:slim-v4


#------------------------------------------------------------------------------
# Other
#------------------------------------------------------------------------------
define SECTION

===============================================================================
= Processing: $@
===============================================================================
endef
