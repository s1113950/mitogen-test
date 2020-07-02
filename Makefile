.PHONY: default

SHELL := /bin/bash

default: run-test


### VARS
# sometimes we wanna run just a vanilla ansible command
ANSIBLE_COMMAND ?= "ansible-playbook"
# dynamically add more flags to playbooks
ANSIBLE_EXTRA_ARGS ?= -vv
# set this to not enter passwords for every test run
ANSIBLE_SSH_PASS ?= ""
ANSIBLE_SUDO_PASS ?= $(ANSIBLE_SSH_PASS)
# dynamically change ansible install version
ANSIBLE_VERSION ?= "2.9.6"
# set this to dynamically change user for test runs
ANSIBLE_USER ?= ""
# only used if USE_DOCKER is true
CONTAINER_IMAGE ?= "centos:8"
# sometimes custom containers want to run something special other than sleep infinity
CONTAINER_RUN_COMMAND ?= sh -c "sleep infinity"
# optional extra args passed to the container when it runs, like "-e arg=val -v..."
CUSTOM_CONTAINER_ARGS ?= ""
# useful for testing dev branches
MITOGEN_INSTALL_BRANCH ?= master
# whether or not to install ANSIBLE_VERSION into the test venv; useful for bleeding edge ansible clones
INSTALL_ANSIBLE ?= true
# which top-level playbook to run
PLAYBOOK ?= run_test
# python2 or python3
PYTHON_VERSION ?= "3"
# set this to false to deploy a container of type CONTAINER_BASE_OS and run tests on that
USE_DOCKER ?= true
# set this to /path/to/local/mitogen/branch to use it without having to 'git commit' repeatedly
USE_LOCAL_MITOGEN ?=
### END VARS

# special test args section
TEST_ARGS := -e test_dir=$(TEST)
ifeq ($(TEST),complex_args)
    TEST_ARGS := $(TEST_ARGS) -e test=true
else ifeq ($(TEST),custom_lib_unpickle)
    TEST_ARGS := $(TEST_ARGS)
# https://github.com/dw/mitogen/issues/672: "ansible localhost -m setup" broke in a python3.5 env with Mitogen
else ifeq ($(TEST),ansible-setup)
	TEST_ARGS := all -c docker -i 'testMitogen,' -e ansible_user=root -e ansible_python_interpreter=/usr/local/bin/python3 -m setup
# sudo fails intermittently: https://github.com/dw/mitogen/issues/726#issuecomment-649221105
else ifeq ($(TEST),ansible-setup-become)
	TEST_ARGS := all -c docker --become -i 'testMitogen,' -e ansible_user=root -u root -m setup
endif

VIRTUALENV_DIR := .venv$(PYTHON_VERSION)
ACTIVATE := $(VIRTUALENV_DIR)/bin/activate
MITOGEN_INSTALL_DIR := /tmp
MITOGEN_INSTALL := $(MITOGEN_INSTALL_DIR)/mitogen/MANIFEST.in


$(ACTIVATE): requirements.txt $(MITOGEN_INSTALL)
	@test -d $(VIRTUALENV_DIR) || ([[ "$(PYTHON_VERSION)" == "3" ]] && python3 -m venv $(VIRTUALENV_DIR) || virtualenv -ppython2 $(VIRTUALENV_DIR))
	@. $(ACTIVATE); pip install --upgrade-strategy only-if-needed -r requirements.txt


$(MITOGEN_INSTALL):
	@test -f $(MITOGEN_INSTALL) || rm -rf $(MITOGEN_INSTALL_DIR)/mitogen && git clone https://github.com/s1113950/mitogen.git $(MITOGEN_INSTALL_DIR)/mitogen


use-local-mitogen:
ifneq ($(USE_LOCAL_MITOGEN),)
	@rsync -a $(USE_LOCAL_MITOGEN)/ $(MITOGEN_INSTALL_DIR)/mitogen
endif

# weird pip install thing is for supporting bleeding edge ansible, ex: git+https://github.com/nitzmahone/ansible.git@a7d0db69142134c2e36a0a62b81a32d9442792ef
install-ansible:
ifeq ($(INSTALL_ANSIBLE),true)
	@. $(ACTIVATE); [[ `pip freeze | grep ansible` == "ansible==$(ANSIBLE_VERSION)" ]] && true || (pip install ansible==$(ANSIBLE_VERSION) || pip install $(ANSIBLE_VERSION))
endif

# ensure we always have the right version of mitogen we want, and then kick off tests
# weird '|| true' thing is because tags can't be pulled that way
run-test: $(ACTIVATE) use-local-mitogen install-ansible
ifeq ($(USE_LOCAL_MITOGEN),)
	@cd $(MITOGEN_INSTALL_DIR)/mitogen && git fetch && git checkout $(MITOGEN_INSTALL_BRANCH) && (git pull origin $(MITOGEN_INSTALL_BRANCH) || true)
endif
	
	@. $(ACTIVATE); $(ANSIBLE_COMMAND) $(ANSIBLE_EXTRA_ARGS) \
	-e use_docker=$(USE_DOCKER) -e container_image=$(CONTAINER_IMAGE) \
	-e container_run_command="'"'$(CONTAINER_RUN_COMMAND)'"'" \
	$(TEST_ARGS) \
	$(shell [[ $(ANSIBLE_COMMAND) == "ansible-playbook" ]] && echo "-b plays/$(PLAYBOOK).yml -i inventory/local") \
	$(shell [ -z $(CUSTOM_CONTAINER_ARGS) ] && echo "-e custom_container_args=''" || echo "-e \"custom_container_args='$(CUSTOM_CONTAINER_ARGS)'\"") \
	$(shell [ -z $(ANSIBLE_SSH_PASS) ] && echo "-k" || echo "-e ansible_ssh_pass=$(ANSIBLE_SSH_PASS)") \
	$(shell [ -z $(ANSIBLE_SUDO_PASS) ] && echo "-K" || echo "-e ansible_sudo_pass=$(ANSIBLE_SUDO_PASS) -e ansible_become_pass=$(ANSIBLE_SUDO_PASS)") \
	$(shell [ -z $(ANSIBLE_USER) ] && echo "-u $(USER)" || echo "-e ansible_user=$(ANSIBLE_USER)")
