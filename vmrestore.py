#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
import time
from config import *
import xml.etree.cElementTree as ET
 
def create_VM(bkp_files_dir):
    xml_file = bkp_files_dir + '/vm.xml'
    temp_template = open(bkp_files_dir + 'temp.tmpl','w')
    tree = ET.ElementTree(file = xml_file)
    root = tree.getroot()
	
    temp_template.write('NAME   = "' + root.findtext('NAME') + '"\r\n')
    context_parse_XML(root, xml_file, temp_template)
    cpu_parse_XML(root, xml_file, temp_template)
    disk_parse_XML(root, bkp_files_dir, temp_template)
    futures_parse_XML(root, xml_file, temp_template)
    graphics_parse_XML(root, xml_file, temp_template)
    user_template_parse_XML(root, xml_file, temp_template)
    temp_template.write('MEMORY = "' + root.findtext('TEMPLATE/MEMORY') + '"\r\n')
    nic_parse_XML(root, xml_file, temp_template)
    os_parse_XML(root, xml_file, temp_template)

    temp_template.close()
    filename = temp_template.name
#    cmd = 'cat '+filename
    cmd = 'onevm create ' + bkp_files_dir+'temp.tmpl' + ' >/dev/null 2>&1'
    os.system(cmd)	
    os.remove(bkp_files_dir + 'temp.tmpl')

def disk_parse_XML(root, bkp_files_dir, temp_template):
    xml_file = bkp_files_dir + '/vm.xml'
    for disk in root.findall('./TEMPLATE/DISK'): 
        image = disk.findtext('IMAGE')
        image_size = disk.findtext('SIZE')
        image_id = disk.findtext('IMAGE_ID')
        persistent = disk.findtext('PERSISTENT')
        datastore_id = disk.findtext('DATASTORE_ID')
#        print image, str(int(image_size)/1024), image_id, persistent, datastore_id
        temp_template.write('DISK = [\r\n  IMAGE = "' + image)
        if persistent:
            temp_template.write('",\r\n  PERSISTENT = "' + persistent)
        temp_template.write('" ]\r\n')	
        for image_filename in os.listdir(bkp_files_dir):
            if image_filename.startswith('one-' + image_id):
                 cmd = ('oneimage create -d ' + datastore_id + ' --name ' + image + ' --type DATABLOCK --size ' +
                         str(int(image_size)/1024) + 'G' + ' --prefix sd --driver raw --path ' + bkp_files_dir + '/' + image_filename + ' >/dev/null 2>&1')
                 os.system(cmd) 				 
#                 print cmd
        if persistent:
            cmd = 'oneimage persistent ' + image + ' >/dev/null 2>&1'
            os.system(cmd)
#        print cmd

def context_parse_XML(root, xml_file, temp_template):
    temp_template.write('CONTEXT = [\r\n  NETWORK = "' + root.findtext('./TEMPLATE/CONTEXT/NETWORK') + '" ]\r\n')

def cpu_parse_XML(root, xml_file, temp_template):
    temp_template.write('CPU = "' + root.findtext('./TEMPLATE/CPU') + '"\r\n')
    temp_template.write('CPU_MODEL = [\r\n  MODEL = "' + root.findtext('./TEMPLATE/CPU_MODEL/MODEL') + '" ]\r\n')
    temp_template.write('VCPU = "' + root.findtext('./TEMPLATE/VCPU') + '"\r\n')

def futures_parse_XML(root, xml_file, temp_template):
    temp_template.write('FEATURES = [\r\n  ACPI = "' + root.findtext('./TEMPLATE/FEATURES/ACPI') + '" ]\r\n')
    	
def graphics_parse_XML(root, xml_file, temp_template):
    temp_template.write('GRAPHICS = [\r\n  LISTEN = "' + root.findtext('./TEMPLATE/GRAPHICS/LISTEN') + '",\r\n' +
     '  TYPE = "' + root.findtext('./TEMPLATE/GRAPHICS/TYPE') + '" ]\r\n')    

def user_template_parse_XML(root, xml_file, temp_template):
    temp_template.write('HYPERVISOR = "' + root.findtext('./USER_TEMPLATE/HYPERVISOR') + '"\r\n')
    temp_template.write('INPUTS_ORDER = "' + root.findtext('./USER_TEMPLATE/INPUTS_ORDER') + '"\r\n')
    temp_template.write('LOGO = "'+root.findtext('./USER_TEMPLATE/LOGO') + '"\r\n')
    temp_template.write('MEMORY_UNIT_COST = "' + root.findtext('./USER_TEMPLATE/MEMORY_UNIT_COST') + '"\r\n')
    temp_template.write('USER_INPUTS = [\r\n  MEMORY = "' + root.findtext('./USER_TEMPLATE/USER_INPUTS/MEMORY') + '" ]\r\n')

def nic_parse_XML(root, xml_file, temp_template):
    temp_template.write('NIC = [\r\n  NETWORK = "' + root.findtext('./TEMPLATE/NIC/NETWORK') + '",\r\n'+
     '  NETWORK_UNAME = "' + root.findtext('./TEMPLATE/NIC/NETWORK_UNAME') + '",\r\n'+
     '  SECURITY_GROUPS = "' + root.findtext('./TEMPLATE/NIC/SECURITY_GROUPS') + '" ]\r\n')
#    mac = root.findtext('./TEMPLATE/NIC/MAC')

def os_parse_XML(root, xml_file, temp_template):    
    temp_template.write('OS = [\r\n  ARCH = "' + root.findtext('./TEMPLATE/OS/ARCH') + '",\r\n'+
     '  BOOT = "' + root.findtext('./TEMPLATE/OS/BOOT') + '",\r\n'+
     '  MACHINE = "' + root.findtext('./TEMPLATE/OS/MACHINE') + '" ]\r\n') 

if __name__ == "__main__":
    create_VM(str(sys.argv[1]))

