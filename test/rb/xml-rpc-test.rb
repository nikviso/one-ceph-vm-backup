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
require './image_test.rb'
require './config.rb'

include OpenNebula

client = Client.new(CREDENTIALS, ENDPOINT)

template_image = <<-EOT
NAME    = "debian-test-rpc"
PATH    = "/var/tmp/backup/backup/debian-vm/8/20190820122013/one-3-8-2"
TYPE    =  "DATABLOCK"
SIZE    =  "10240"
EOT

image_pool = ImagePool.new(client, -1)

rc = image_pool.info
if OpenNebula.is_error?(rc)
     puts rc.message
     exit -1
end

image_id = get_image_id(image_pool,'debian-test-rpc')
puts image_id


image = Image.new(Image.build_xml(image_id),client)
#rc = image.allocate(template_image,101)
rc = image.info
     if OpenNebula.is_error?(rc)
          puts "IMAGE #{image.id}: #{rc.message}"
     else
          puts "IMAGE->#{image.name} : STATE->#{image.state} : ID->#{image.id}"
     end
=begin
=end
exit 0
