#!/usr/bin/env python
# -*- coding: utf-8 -*-

import pyone
import time
from config import *

"""
my_image = one.imagepool.info(-1,-1,-1,-1).IMAGE[1]
print my_image.get_ID()
print my_image.get_NAME()
print my_image.get_STATE()
"""

"""
template = 'NAME    = "Red LAN"\r\n\
BRIDGE  = vbr0\r\n\
GATEWAY = 192.168.0.1\r\n\
DNS     = 192.168.0.1\r\n\
LOAD_BALANCER = 192.168.0.3\r\n\
AR = [\r\n\
    TYPE = IP4,\r\n\
    IP   = 192.168.0.1,\r\n\
    SIZE = 255\
]'
print template
"""

"""ОК
my_image = one.image.info(14)
print my_image.ID
print my_image.NAME
print my_image.PERSISTENT
print my_image.PATH
print my_image.SOURCE
print my_image.FSTYPE
print my_image.STATE
print my_image.TYPE
"""

"""ОК
try:
   print one.vm.info(21).STATE
except pyone.OneNoExistsException as err:
   print(err)
"""

"""ОК
print one.vm.info(one.vmpool.info(-1,-1,-1,-1,'debian-vm').VM[0].get_ID()).NAME
print one.vmpool.info(-1,-1,-1,-1,'debian-vm').VM[0].get_ID()
one.vm.action('suspend', one.vmpool.info(-1,-1,-1,-1,'debian-vm').VM[0].get_ID())
while one.vmpool.info(-1,-1,-1,-1,'debian-vm').VM[0].get_STATE() == 3:
    time.sleep(3)
print one.vmpool.info(-1,-1,-1,-1,'debian-vm').VM[0].get_STATE()
"""

"""ОК
print one.vm.info(one.vmpool.info(-1,-1,-1,-1,'debian-vm').VM[0].get_ID()).NAME
print one.vmpool.info(-1,-1,-1,-1,'debian-vm').VM[0].get_ID()
one.vm.action('resume', one.vmpool.info(-1,-1,-1,-1,'debian-vm').VM[0].get_ID())
while one.vmpool.info(-1,-1,-1,-1,'debian-vm').VM[0].get_STATE() != 3:
    time.sleep(3)
print one.vmpool.info(-1,-1,-1,-1,'debian-vm').VM[0].get_STATE()
"""

"""
The action String must be one of the following:
terminate-hard
terminate
undeploy-hard
undeploy
poweroff-hard
poweroff
reboot-hard
reboot
hold
release
stop
suspend
resume
resched
unresched
"""

"""ОК
my_vm_state = one.vmpool.info(-1,-1,-1,-1,'debian-vm').VM[0].get_STATE()
my_vm_id = one.vmpool.info(-1,-1,-1,-1,'debian-vm').VM[0].get_ID()
my_vm_name = one.vmpool.info(-1,-1,-1,-1,'debian-vm').VM[0].get_NAME()
print my_vm_state
print my_vm_id
print my_vm_name
"""

"""ОК
try:
   print one.vmpool.info(-1,-1,-1,-1,'debian-vm23').VM[0].get_ID()
except IndexError as err:
   print(err)
"""

"""ОК
one.vm.action('stop', 21)
one.vm.action('resume', 21)
"""