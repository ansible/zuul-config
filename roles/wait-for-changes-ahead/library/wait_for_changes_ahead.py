#!/usr/bin/python

# Copyright (c) 2018 Red Hat
#
# This module is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this software.  If not, see <http://www.gnu.org/licenses/>.
from __future__ import absolute_import, division, print_function
import traceback
import json
import time
from six.moves import urllib
from ansible.module_utils.basic import AnsibleModule

__metaclass__ = type

DOCUMENTATION = '''
---
module: wait_for_changes_ahead
short_description: Wait for zuul queue
author: Tristan de Cacqueray (@tristanC)
description:
  - Wait for zuul queue ahead to SUCCEED
requirements:
  - "python >= 3.5"
options:
  zuul_web_url:
    description:
      - The zuul web url to query change status
    required: true
    type: str
  zuul_change:
    description:
      - The change nr, patchset nr
    required: true
    type: str
  wait_timeout:
    description:
      - The maximum waiting time
    default: 7200
    type: int
'''

log = list()


def main():
    module = AnsibleModule(
        argument_spec=dict(
            zuul_status_url=dict(required=True, type='str'),
            zuul_change=dict(required=True, type='str'),
            wait_timeout=dict(type='int'),
        )
    )
    zuul_status_url = module.params['zuul_status_url']
    zuul_change = module.params['zuul_change']
    wait_timeout = module.params.get('wait_timeout', 120)
    if not wait_timeout:
        wait_timeout = 120
    wait_timeout = int(wait_timeout) * 60

    if False:
        module.exit_json(changed=False, msg="noop")
    try:
        start_time = time.monotonic()
        while True:
            req = urllib.request.urlopen(
                zuul_status_url + "/change/%s" % zuul_change)
            changes = json.loads(req.read().decode('utf-8'))

            if not changes:
                module.fail_json(msg="Unknown change", log="\n".join(log))

            found = None
            for change in changes:
                if change["live"] is True:
                    found = change
                    break

            if found and not change["item_ahead"]:
                break

            if time.monotonic() - start_time > wait_timeout:
                module.fail_json(msg="Timeout", log="\n".join(log))

            time.sleep(30)
    except Exception as e:
        tb = traceback.format_exc()
        log.append(str(e))
        log.append(tb)
        module.fail_json(msg=str(e), log="\n".join(log))
    finally:
        log_text = "\n".join(log)
    module.exit_json(changed=False, msg=log_text)


if __name__ == '__main__':
    main()
