# mitogen-test
Place to store sample playbooks for the purpose of testing mitogen patches

## How to run a test
`TEST=${TEST_DIR} make run-test` where `TEST_DIR` is a subdir of the `run_test` role.

Set `USE_DOCKER=false` to run on localhost.

## Supported docker images:
Set `CONTAINER_IMAGE` (optionally) to one of the following:

`centos:{6|7|8|8.1.1911}`

`ubuntu{14.04|16.04|18.04|19.10|20.04}`

`roboxes/rhel8:2.0.6`

Defaults to `centos:8`.

## Subdirs

### complex_args
Validates patch https://github.com/dw/mitogen/pull/658

### custom_lib_unpickle
Validates https://github.com/dw/mitogen/issues/689

### wait_for_connection
Validates https://github.com/dw/mitogen/issues/655
