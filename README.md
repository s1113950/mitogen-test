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

`fvissing/ansible:77389e9a8b9c` from https://github.com/dw/mitogen/issues/672#issuecomment-635515926

Defaults to `centos:8`.


## Tests in run_test

### collections
Validates https://github.com/dw/mitogen/issues/652

### complex_args
Validates patch https://github.com/dw/mitogen/pull/658

### custom_lib_unpickle
Validates https://github.com/dw/mitogen/issues/689

### misc
Validates https://github.com/dw/mitogen/issues/716

### wait_for_connection
Validates https://github.com/dw/mitogen/issues/655

## Playbook-level tests

### plays/collections.yml
Validates https://github.com/dw/mitogen/issues/652
