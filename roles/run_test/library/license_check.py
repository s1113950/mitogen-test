#!/usr/bin/python

# ripped from https://github.com/dw/mitogen/issues/689#issuecomment-602702713
from ansible.module_utils.basic import AnsibleModule
from datetime import datetime
from datetime import timedelta
import re
import os

def main():

  result = dict(
    changed = False,
    warnings = [],
    renewal_date = ''
  )

  module = AnsibleModule(
    argument_spec = dict(
      license_file = dict(required=True),
      warning_weeks = dict(required=False, type='int', default=12)
    ),
    supports_check_mode=True
  )

  pattern = re.compile("^key.renewal=(.*)")

  try:
    for line in open(module.params['license_file']):
      for match in re.finditer(pattern, str(line)):
        expiry_date = datetime.strptime(match.group(1), '%Y%m%d')
        result['renewal_date'] = expiry_date.strftime('%Y-%m-%d')
        expiry_window = expiry_date - timedelta(weeks=module.params['warning_weeks'])
        now = datetime.now()

        if expiry_date < now:
          fail_msg = 'The license expired on ' + expiry_date.strftime('%d %b %Y') + '.'
          module.fail_json(msg = fail_msg)

        elif expiry_window < now:
          fail_msg = 'The license is due to expire on ' + expiry_date.strftime('%d %b %Y') + '.'
          result['warnings'].append(fail_msg)

  except IOError:
    module.fail_json(msg = 'Could not open the requested file: ' + module.params['license_file'])

  module.exit_json(**result)

if __name__ == '__main__':
  main();
