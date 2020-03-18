.PHONY: default

SHELL := /bin/bash

default: complex-args-test

VIRTUALENV_DIR := .venv
ACTIVATE := $(VIRTUALENV_DIR)/bin/activate
MITOGEN_INSTALL_DIR := /tmp
MITOGEN_INSTALL := $(MITOGEN_INSTALL_DIR)/mitogen/MANIFEST.in

ANSIBLE_EXTRA_ARGS ?= -vv

# set this to dynamically change user for test runs
ANSIBLE_USER ?= ""
# set this to not enter password for every test run
ANSIBLE_SSH_PASS ?= ""
ANSIBLE_SUDO_PASS ?= $(ANSIBLE_SSH_PASS)

# set this to true to deploy a container of type CONTAINER_BASE_OS and run tests on that locally
USE_DOCKER ?= "false"
# only used if USE_DOCKER is set

# supported images:
# centos 6,7,8,8.1.1911
# ubuntu 14.04,16.04,18.04,19.10,20.04
# roboxes/rhel8:2.0.6
CONTAINER_IMAGE ?= "centos:8"

$(ACTIVATE): requirements.txt $(MITOGEN_INSTALL)
	@test -d $(VIRTUALENV_DIR) || python3 -m venv $(VIRTUALENV_DIR)
	@. $(ACTIVATE); pip install --upgrade-strategy only-if-needed -r requirements.txt

$(MITOGEN_INSTALL):
	@test -f $(MITOGEN_INSTALL) || rm -rf $(MITOGEN_INSTALL_DIR)/mitogen && git clone https://github.com/s1113950/mitogen.git $(MITOGEN_INSTALL_DIR)/mitogen
	@cd $(MITOGEN_INSTALL_DIR)/mitogen && git checkout complexAnsiblePythonInterpreterArg && git pull origin complexAnsiblePythonInterpreterArg

complex-args-test: $(ACTIVATE)
	@. $(ACTIVATE); ansible-playbook $(ANSIBLE_EXTRA_ARGS) -i inventory/local \
	-e use_docker=$(USE_DOCKER) -e container_image=$(CONTAINER_IMAGE) -b plays/complex_args.yml \
	$(shell [ -z $(ANSIBLE_SSH_PASS) ] && echo "-k" || echo "-e ansible_ssh_pass=$(ANSIBLE_SSH_PASS)") \
	$(shell [ -z $(ANSIBLE_SUDO_PASS) ] && echo "-K" || echo "-e ansible_sudo_pass=$(ANSIBLE_SUDO_PASS)") \
	$(shell [ -z $(ANSIBLE_USER) ] && echo "-u $(USER)" || echo "-e ansible_user=$(ANSIBLE_USER)") \
