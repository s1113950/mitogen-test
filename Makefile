.PHONY: default

SHELL := /bin/bash

default: complex-args-test

VIRTUALENV_DIR := .venv
ACTIVATE := $(VIRTUALENV_DIR)/bin/activate
MITOGEN_INSTALL_DIR := /tmp
MITOGEN_INSTALL := $(MITOGEN_INSTALL_DIR)/mitogen/MANIFEST.in
# useful for testing dev branches
MITOGEN_INSTALL_BRANCH ?= master

ANSIBLE_EXTRA_ARGS ?= -vv

# set this to dynamically change user for test runs
ANSIBLE_USER ?= ""
# set this to not enter password for every test run
ANSIBLE_SSH_PASS ?= ""
ANSIBLE_SUDO_PASS ?= $(ANSIBLE_SSH_PASS)

# set this to false to deploy a container of type CONTAINER_BASE_OS and run tests on that
USE_DOCKER ?= true
# only used if USE_DOCKER is true
CONTAINER_IMAGE ?= "centos:8"

TEST_ARGS := -e test_dir=$(TEST)

# special test args section
ifeq ($(TEST),complex_args)
    TEST_ARGS := $(TEST_ARGS) -e test=true
else ifeq ($(TEST),custom_lib_unpickle)
    TEST_ARGS := $(TEST_ARGS)
endif


$(ACTIVATE): requirements.txt $(MITOGEN_INSTALL)
	@test -d $(VIRTUALENV_DIR) || python3 -m venv $(VIRTUALENV_DIR)
	@. $(ACTIVATE); pip install --upgrade-strategy only-if-needed -r requirements.txt


$(MITOGEN_INSTALL):
	@test -f $(MITOGEN_INSTALL) || rm -rf $(MITOGEN_INSTALL_DIR)/mitogen && git clone https://github.com/s1113950/mitogen.git $(MITOGEN_INSTALL_DIR)/mitogen


# helps with debugging PRs, set MITOGEN_INSTALL_BRANCH to use
ensure-branch-checked-out:
	@cd $(MITOGEN_INSTALL_DIR)/mitogen && git fetch && git checkout $(MITOGEN_INSTALL_BRANCH) && git pull origin $(MITOGEN_INSTALL_BRANCH)


run-test: $(ACTIVATE) ensure-branch-checked-out
	@. $(ACTIVATE); ansible-playbook $(ANSIBLE_EXTRA_ARGS) -i inventory/local \
	-e use_docker=$(USE_DOCKER) -e container_image=$(CONTAINER_IMAGE) -b plays/run_test.yml \
	$(TEST_ARGS) \
	$(shell [ -z $(ANSIBLE_SSH_PASS) ] && echo "-k" || echo "-e ansible_ssh_pass=$(ANSIBLE_SSH_PASS)") \
	$(shell [ -z $(ANSIBLE_SUDO_PASS) ] && echo "-K" || echo "-e ansible_sudo_pass=$(ANSIBLE_SUDO_PASS)") \
	$(shell [ -z $(ANSIBLE_USER) ] && echo "-u $(USER)" || echo "-e ansible_user=$(ANSIBLE_USER)")
