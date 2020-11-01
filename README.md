# mitogen-test
Place to store sample playbooks for the purpose of testing mitogen patches

## How to run a test
Most tests: `TEST=${TEST_DIR} make run-test` where `TEST_DIR` is a subdir of the `run_test` role.
Set `USE_DOCKER=false` to run on localhost.

Collection playbook-level test:
`PLAYBOOK=collections make run-test`


## Supported docker images:
Set `CONTAINER_IMAGE` (optionally) to one of the following:

`centos:{6|7|8|8.1.1911}`

`ubuntu{14.04|16.04|18.04|19.10|20.04}`

`roboxes/rhel8:2.0.6`

`willhallonline/ansible:2.9-alpine` from https://github.com/dw/mitogen/issues/673#issuecomment-633248152

Defaults to `centos:8`.


## Tests in run_test

### async-ansible-2-10
Validates https://github.com/dw/mitogen/blob/master/tests/ansible/integration/async/runner_one_job.yml#L11 for Ansible 2.10

### collections
Validates https://github.com/dw/mitogen/issues/652

### complex_args
Validates patch https://github.com/dw/mitogen/pull/658

### custom_lib_unpickle
Validates https://github.com/dw/mitogen/issues/689

### custom-python-new-style-module-ansible-2-10
Validates custom_python_new_style_module.yml for Ansible 2.10

### debops
Validates running `debops common` on a created `CONTAINER_IMAGE` using Mitogen. Currently fails due to a bug in debops.

### misc
Validates https://github.com/dw/mitogen/issues/716

### paramiko-ansible-2-10
Validates https://github.com/dw/mitogen/blob/master/tests/ansible/integration/connection_loader/paramiko_unblemished.yml#L3 for Ansible 2.10

### perms
Validates https://github.com/dw/mitogen/issues/734

### perms-ansible-2-10
Validates https://github.com/dw/mitogen/blob/master/tests/ansible/integration/action/fixup_perms2__copy.yml#L29 for Ansible 2.10

### wait_for_connection
Validates https://github.com/dw/mitogen/issues/655

## Playbook-level tests

### plays/collections.yml
Validates https://github.com/dw/mitogen/issues/652

### plays/missing-module-ansible-2-10
Validates https://github.com/dw/mitogen/blob/master/tests/ansible/integration/runner/missing_module.yml#L19, Ansible 2.10 removed the `.` in the error msg

### plays/mixed-mitogen-vanilla-ansible-2-10
Validates https://github.com/dw/mitogen/blob/master/tests/ansible/integration/strategy/_mixed_mitogen_vanilla.yml#L25 for Ansible 2.10

### plays/tc-become-pass-ansible-2-10
Validates https://github.com/dw/mitogen/blob/master/tests/ansible/integration/transport_config/become_pass.yml#L1 for Ansible 2.10

### ansible tests (not ansible-playbook)
Validates https://github.com/dw/mitogen/issues/672

To set up test container:
```
TEST=misc CONTAINER_IMAGE=python:3.5.3-jessie make run-test
```
run to test inside of it:
```
TEST=ansible-setup ANSIBLE_COMMAND=ansible make run-test
```

Validates https://github.com/dw/mitogen/issues/726

To set up test container:
```
TEST=misc CONTAINER_IMAGE=centos:7 ANSIBLE_VERSION=2.9.9 make run-test
```
run to test inside of it:
```
TEST=ansible-setup-become ANSIBLE_COMMAND=ansible INSTALL_ANSIBLE=false ANSIBLE_SSH_PASS='***' make run-test
```
