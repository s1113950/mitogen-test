.PHONY: default

SHELL := /bin/bash

default: complex-args-test

VIRTUALENV_DIR := .venv
ACTIVATE := $(VIRTUALENV_DIR)/bin/activate
MITOGEN_INSTALL_DIR := /tmp
MITOGEN_INSTALL := $(MITOGEN_INSTALL_DIR)/mitogen/MANIFEST.in

ANSIBLE_EXTRA_ARGS ?= '-vv'

$(ACTIVATE): requirements.txt $(MITOGEN_INSTALL)
	@test -d $(VIRTUALENV_DIR) || python3 -m venv $(VIRTUALENV_DIR)
	@. $(ACTIVATE); pip install --upgrade-strategy only-if-needed -r requirements.txt

$(MITOGEN_INSTALL):
	@test -f $(MITOGEN_INSTALL) || rm -rf $(MITOGEN_INSTALL_DIR)/mitogen && git clone https://github.com/s1113950/mitogen.git $(MITOGEN_INSTALL_DIR)/mitogen
	@cd $(MITOGEN_INSTALL_DIR)/mitogen && git checkout complexAnsiblePythonInterpreterArg && git pull origin complexAnsiblePythonInterpreterArg

complex-args-test: $(ACTIVATE)
	@. $(ACTIVATE); ansible-playbook $(ANSIBLE_EXTRA_ARGS) -i inventory/local -b plays/complex_args.yml
