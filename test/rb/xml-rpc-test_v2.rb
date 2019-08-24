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
=begin
template_image = <<-EOT
NAME    = "debian-test-rpc"
PATH    = "/var/tmp/backup/backup/debian-vm/8/20190820122013/one-3-8-2"
TYPE    = "DATABLOCK"
SIZE    = "10240"
EOT
=end

TEMPLATE = File.read("/var/tmp/backup/backup/debian-vm3/22/20190820121921/vm.xml") 

xml = Nokogiri::XML(TEMPLATE)

xml.xpath("//VM/TEMPLATE/DISK").each_with_index{|parent_elem, parent_count| 
  puts "Disk #{parent_count + 1}"
  @template_image = "TYPE =  \"DATABLOCK\"\n"
  parent_elem.elements.each{|child_elem|
   @image  = child_elem.at_xpath('//IMAGE').text
   if child_elem.name == "DATASTORE_ID"
      @datastore_id = child_elem.text
   end	  
   if child_elem.name == "IMAGE" || child_elem.name == "SIZE"
     @template_image = @template_image + "#{child_elem.name.to_s} = \"#{child_elem.text}\"\n"
   end  	
  }
  puts @image   
  puts @template_image  
  puts @datastore_id
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
