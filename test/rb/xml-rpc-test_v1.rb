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
TYPE    =  "DATABLOCK"
SIZE    =  "10240"
EOT
=end

=begin
#OK
xml_pool = Nokogiri::XML(open('/var/tmp/backup/backup/debian-vm3/22/20190820121921/vm.xml'))
puts xml_pool.xpath('//VM//DISK//IMAGE').text
=end


TEMPLATE = File.read("/var/tmp/backup/backup/debian-vm3/22/20190820121921/vm.xml") 

=begin
#OK
reader = Nokogiri::XML::Reader(TEMPLATE)
reader.each do |node|
  # node is an instance of Nokogiri::XML::Reader
  puts node.name
end
=end

xml = Nokogiri::XML(TEMPLATE)

=begin
#OK
xml.xpath("//VM/TEMPLATE/DISK/*").each{|e|
#  puts "#{e.name}:#{e.text}" 
   if e.name == "IMAGE" || e.name == "ORIGINAL_SIZE" || e.name == "SIZE" || e.name == "DATASTORE_ID"
@template_image = "#{e.name} = #{e.text}"
#     puts "#{e.name} = #{}"
   end
}
puts @template_image
=end

 xml.xpath("//VM/TEMPLATE/DISK").each_with_index{|parent_elem, parent_count| 
  puts "Disk #{parent_count + 1}"
  
  parent_elem.elements.each{|child_elem|
  if child_elem.name == "IMAGE" || child_elem.name == "SIZE" || child_elem.name == "DATASTORE_ID"  
    template_image = "#{child_elem.name.to_s} = \"#{child_elem.text}\""
	puts template_image
  end  	
  }

}



=begin
#xml_pool =  XMLPool.new('/var/tmp/backup/backup/debian-vm/8/20190820122013/vm.xml')
#xml_pool = XMLElement.new(TEMPLATE)
image_pool = XMLElement.build_xml(TEMPLATE,'VM')
#puts image_pool
image_pool.each do |image|
     rc = image['<IMAGE>']
     if OpenNebula.is_error?(rc)
          puts "IMAGE #{image.id}: #{rc.message}"
     else
puts rc
#          puts "IMAGE #{image.name}: #{image.state}: #{image.id}"
#          return image.id 
     end
   end

#puts xml_pool.attr('//VM//NAME','NAME')


   do |image|
     rc = image.info
     if OpenNebula.is_error?(rc)
          puts "IMAGE #{image.id}: #{rc.message}"
     else
	    if image.name == image_name
#          puts "IMAGE #{image.name}: #{image.state}: #{image.id}"
#          return image.id 
	    end  
     end
   end
=end


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

#image = Image.new(Image.build_xml(),client)
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
