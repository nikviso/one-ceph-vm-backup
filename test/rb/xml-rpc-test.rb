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

TEMPLATE = File.read(@backup_path + "/vm.xml") 
xml = Nokogiri::XML(TEMPLATE)

@vm_id = xml.xpath("//VM//ID").text

xml.xpath("//VM//TEMPLATE//DISK").each{|elem| 
  template_image = "TYPE = \"DATABLOCK\"\n"
  image_name  = elem.xpath('IMAGE').text  
  datastore_id = elem.xpath('DATASTORE_ID').text.to_i
  size = elem.xpath('SIZE').text
  source = elem.xpath('SOURCE').text
  @persistent = elem.xpath('PERSISTENT').text
  path = @backup_path + "/one-" + elem.xpath('IMAGE_ID').text
  if @persistent == ""; path = path + "-" + @vm_id + "-" + elem.xpath('DISK_ID').text end
  template_image = template_image + "NAME = \"#{image_name}\"\n" + "SIZE = \"#{size}\"\n" + "PATH = \"#{path}\"\n"
#  	"SOURCE = #{source}\n" +	
  image_id = get_image_id(get_image_pool(client),image_name)		   
  if @persistent != ""  
    if image_id == 0
       image = Image.new(Image.build_xml(),client)
       rc = image.allocate(template_image,datastore_id)	
       if OpenNebula.is_error?(rc)
          puts rc.message
          exit -1
       end
       image_id = get_image_id(get_image_pool(client),image_name)
       image = Image.new(Image.build_xml(image_id),client)
       image.persistent
    else
       puts "Error allocating a new image. NAME \"#{image_name}\" is already taken by IMAGE #{image_id}."
    end 
  else
    puts "Disk is NON PERSISTENT"
  end
#  puts @persistent
  puts template_image
  puts datastore_id  
  puts image_id	
#  system ("ls #{path}")
}

exit 0
