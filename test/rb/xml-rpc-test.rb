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

@backup_path = ARGV[0].to_s

##############################################################################
# Required libraries
##############################################################################
require 'opennebula'
require './dp.rb'
require './config.rb'
include OpenNebula

client = Client.new(CREDENTIALS, ENDPOINT)
=begin
template_image = <<-EOT
NAME    = "debian-test-rpc"
PATH    = "/var/tmp/backup/backup/debian-vm/8/20190820122013/one-3-8-2"
TYPE    = "DATABLOCK"
SIZE    = "10240"
EOT
=end

TEMPLATE = File.read(@backup_path + "/vm.xml") 

xml = Nokogiri::XML(TEMPLATE)

xml.xpath("//VM//TEMPLATE//DISK").each{|elem| 
  template_image = "TYPE =  \"DATABLOCK\"\n"
  image  = elem.xpath('IMAGE').text  
  datastore_id = elem.xpath('DATASTORE_ID').text
  size = elem.xpath('SIZE').text
  source = elem.xpath('SOURCE').text
  path = @backup_path + "/one-" + elem.xpath('IMAGE_ID').text + "-*-" + elem.xpath('DISK_ID').text
  template_image = template_image + "IMAGE = #{image}\n" + "SIZE = #{size}\n" + 
                   "SOURCE = #{source}\n" + "PATH = #{path}\n" 
  puts template_image
  puts datastore_id
  puts "\n"
  system ("ls #{path}")
}
 


=begin
#OK
image_pool = ImagePool.new(client, -1)

rc = image_pool.info
if OpenNebula.is_error?(rc)
     puts rc.message
     exit -1
end

image_id = get_image_id(image_pool,'debian-test-rpc')
puts image_id

#rc = image.allocate(template_image,101)

image = Image.new(Image.build_xml(image_id),client)

rc = image.info
     if OpenNebula.is_error?(rc)
          puts "IMAGE #{image.id}: #{rc.message}"
     else
          puts "IMAGE->#{image.name} : STATE->#{image.state} : ID->#{image.id}"
     end

=end
exit 0
