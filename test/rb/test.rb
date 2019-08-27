#!/usr/bin/env ruby

##############################################################################
# Environment Configuration
##############################################################################
ONE_LOCATION=ENV["ONE_LOCATION"]

if !ONE_LOCATION
    RUBY_LIB_LOCATION="/usr/lib/one/ruby"
else
    RUBY_LIB_LOCATION=ONE_LOCATION+"/lib/ruby"
end

$: << RUBY_LIB_LOCATION

##############################################################################
# Required libraries
##############################################################################
require 'opennebula'
require './dp.rb'
require './config.rb'
include OpenNebula

client = Client.new(CREDENTIALS, ENDPOINT)

template_image = <<-EOT
NAME    = "debian-test-rpc2"
PATH    = "/var/tmp/backup/backup/debian-vm2/18/20190820121951/one-14"
TYPE    =  "DATABLOCK"
SIZE    =  "10240"
EOT

image = Image.new(Image.build_xml(),client)
rc = image.allocate(template_image,101)
     if OpenNebula.is_error?(rc)
        puts rc.message
        exit -1
     end