.PHONY: default

SHELL := /bin/bash

default: run-test


### VARS
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
# useful for testing dev branches
MITOGEN_INSTALL_BRANCH ?= master
# whether or not to install ANSIBLE_VERSION into the test venv; useful for bleeding edge ansible clones
NO_INSTALL_ANSIBLE ?= ""
# which top-level playbook to run
PLAYBOOK ?= run_test
# python2 or python3
PYTHON_VERSION ?= "3"
# set this to false to deploy a container of type CONTAINER_BASE_OS and run tests on that
USE_DOCKER ?= true
# set this to /path/to/local/mitogen/branch to use it without having to 'git commit' repeatedly
USE_LOCAL_MITOGEN ?= ""
### END VARS

# special test args section
TEST_ARGS := -e test_dir=$(TEST)
ifeq ($(TEST),complex_args)
    TEST_ARGS := $(TEST_ARGS) -e test=true
else ifeq ($(TEST),custom_lib_unpickle)
    TEST_ARGS := $(TEST_ARGS)
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
ifneq ($(USE_LOCAL_MITOGEN),"")
	@rsync -a $(USE_LOCAL_MITOGEN)/ $(MITOGEN_INSTALL_DIR)/mitogen
endif

# weird pip install thing is for supporting bleeding edge ansible, ex: git+https://github.com/nitzmahone/ansible.git@a7d0db69142134c2e36a0a62b81a32d9442792ef
install-ansible:
ifeq ($(NO_INSTALL_ANSIBLE),"")
	@. $(ACTIVATE); [[ `pip freeze | grep ansible` == "ansible==$(ANSIBLE_VERSION)" ]] && true || (pip install ansible==$(ANSIBLE_VERSION) || pip install $(ANSIBLE_VERSION))
endif

# ensure we always have the right version of mitogen we want, and then kick off tests
# weird '|| true' thing is because tags can't be pulled that way
run-test: $(ACTIVATE) use-local-mitogen install-ansible
ifeq ($(USE_LOCAL_MITOGEN),"")
	@cd $(MITOGEN_INSTALL_DIR)/mitogen && git fetch && git checkout $(MITOGEN_INSTALL_BRANCH) && (git pull origin $(MITOGEN_INSTALL_BRANCH) || true)
endif
	
	@. $(ACTIVATE); ansible-playbook $(ANSIBLE_EXTRA_ARGS) -i inventory/local \
	-e use_docker=$(USE_DOCKER) -e container_image=$(CONTAINER_IMAGE) -b plays/$(PLAYBOOK).yml \
	$(TEST_ARGS) \
	$(shell [ -z $(ANSIBLE_SSH_PASS) ] && echo "-k" || echo "-e ansible_ssh_pass=$(ANSIBLE_SSH_PASS)") \
	$(shell [ -z $(ANSIBLE_SUDO_PASS) ] && echo "-K" || echo "-e ansible_sudo_pass=$(ANSIBLE_SUDO_PASS) -e ansible_become_pass=$(ANSIBLE_SUDO_PASS)") \
	$(shell [ -z $(ANSIBLE_USER) ] && echo "-u $(USER)" || echo "-e ansible_user=$(ANSIBLE_USER)")
