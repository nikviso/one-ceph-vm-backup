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
require 'optparse'
include OpenNebula

$options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: vmrestore.rb [options]"
  
  opts.on("-pNAME", "--path=/PATH/TO/BACKUP/DIR", "Path to backup directory") do |p|
    $backup_path = p
  end  

  opts.on("-v", "--verbose", "Run verbosely") do |v|
    $options[:verbose] = v
  end

  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end  
  
end.parse!



if($backup_path != nil)
    TEMPLATE = File.read($backup_path + "/vm.xml") 
else
    puts "Path to backup directory is empty"
    exit -1	
end

client = Client.new(CREDENTIALS, ENDPOINT)

xml = Nokogiri::XML(TEMPLATE)

def context_parse_XML(xml)
    $template_vm = $template_vm + "CONTEXT = [\r\n  NETWORK = \"#{xml.xpath("//VM//TEMPLATE//CONTEXT//NETWORK").text}\" ]\n"
end

def cpu_parse_XML(xml)
    $template_vm = $template_vm + "CPU = \"#{xml.xpath("//VM//TEMPLATE//CPU").text}\"\n"
    $template_vm = $template_vm + "CPU_MODEL = \"#{xml.xpath("//VM//TEMPLATE//CPU_MODEL/MODEL").text}\"\n"
    $template_vm = $template_vm + "VCPU = \"#{xml.xpath("//VM//TEMPLATE//VCPU").text}\"\n"
end

def disk_parse_XML(xml,client)
   vm_id = xml.xpath("//VM//ID").text
   xml.xpath("//VM//TEMPLATE//DISK").each{|elem| 
     template_image = "TYPE = \"DATABLOCK\"\n"
     image_name  = elem.xpath('IMAGE').text  
     datastore_id = elem.xpath('DATASTORE_ID').text.to_i
     size = elem.xpath('SIZE').text
     source = elem.xpath('SOURCE').text
     persistent = elem.xpath('PERSISTENT').text
     path = $backup_path + "/one-" + elem.xpath('IMAGE_ID').text
     if persistent == ""; path = path + "-" + vm_id + "-" + elem.xpath('DISK_ID').text end
     template_image = template_image + "NAME = \"#{image_name}\"\n" + "SIZE = \"#{size}\"\n" + "PATH = \"#{path}\"\n"
     image_id = get_image_id(get_image_pool(client),image_name)		   
     if persistent != ""  
       if image_id == 0
          image = Image.new(Image.build_xml,client)
          rc = image.allocate(template_image,datastore_id)	
          if OpenNebula.is_error?(rc)
             puts rc.message
             exit -1
          end
#          image_id = get_image_id(get_image_pool(client),image_name)
#          image = Image.new(Image.build_xml(image_id),client)
          image.persistent
          puts "Has been allocated IMAGE NAME \"#{image_name}\" by ID:#{image.id.to_s}"
       else
          puts "Error allocating a new image. NAME \"#{image_name}\" is already taken by IMAGE ID #{image_id}."
          exit -1 
       end 
     else
       puts "Disk \"#{image_name}\" is NONPERSISTENT"
       exit -1  
     end
     if $options[:verbose]
       puts "IMAGE TEMPLATE:\n#{template_image}\n"
       puts "DATASTORE ID:#{datastore_id}; IMAGE ID:#{image_id}; PERSISTENT:#{persistent}"
       puts "\n"	   
#      system ("ls #{path}")
     end 
     $template_vm = $template_vm + "DISK = [\n  IMAGE = \"#{image_name}\""
     if persistent != ""
       $template_vm = $template_vm + ",\n  PERSISTENT = \"#{persistent}\""
     end	
     $template_vm = $template_vm + " ]\n"	
   }
end

def futures_parse_XML(xml)
    $template_vm = $template_vm + "FEATURES = [\n  ACPI = \"#{xml.xpath("//VM//TEMPLATE//FEATURES//ACPI").text}\""
    $template_vm = $template_vm + " ]\n"    	
end

def graphics_parse_XML(xml)
    $template_vm = $template_vm + "GRAPHICS = [\n  LISTEN = \"#{xml.xpath("//VM//TEMPLATE//GRAPHICS//LISTEN").text}\",\n"
    $template_vm = $template_vm + "  TYPE = \"#{xml.xpath("//VM//TEMPLATE//GRAPHICS/TYPE").text}\""
    $template_vm = $template_vm + " ]\n"    	
end

def user_template_parse_XML(xml)
    $template_vm = $template_vm + "HYPERVISOR = \"#{xml.xpath("//VM//USER_TEMPLATE//HYPERVISOR").text}\"\n"
    $template_vm = $template_vm + "INPUTS_ORDER = \"#{xml.xpath("//VM//USER_TEMPLATE/INPUTS_ORDER").text}\"\n"
    $template_vm = $template_vm + "LOGO = \"#{xml.xpath("//VM//USER_TEMPLATE//LOGO").text}\"\n"	
    $template_vm = $template_vm + "MEMORY_UNIT_COST = \"#{xml.xpath("//VM//USER_TEMPLATE//MEMORY_UNIT_COST").text}\"\n"
    $template_vm = $template_vm + "USER_INPUTS = [\n  MEMORY = \"#{xml.xpath("//VM//USER_TEMPLATE//USER_INPUTS//MEMORY").text}\""
    $template_vm = $template_vm + " ]\n"    	
end

def nic_parse_XML(xml)
    $template_vm = $template_vm + "NIC = [\n  NETWORK = \"#{xml.xpath("//VM//TEMPLATE//NIC//NETWORK").text}\",\n"
#    $template_vm = $template_vm + "  MAC = \"#{xml.xpath("//VM//TEMPLATE//NIC//MAC").text}\",\n"
    $template_vm = $template_vm + "  DNS = \"#{xml.xpath("//VM//TEMPLATE//NIC//DNS").text}\",\n"
    $template_vm = $template_vm + "  GATEWAY = \"#{xml.xpath("//VM//TEMPLATE//NIC//GATEWAY").text}\",\n"
    $template_vm = $template_vm + "  IP = \"#{xml.xpath("//VM//TEMPLATE//NIC//IP").text}\",\n"
    $template_vm = $template_vm + "  NETWORK_ADDRESS = \"#{xml.xpath("//VM//TEMPLATE//NIC//NETWORK_ADDRESS").text}\",\n"
    $template_vm = $template_vm + "  NETWORK_MASK = \"#{xml.xpath("//VM//TEMPLATE//NIC//NETWORK_MASK").text}\",\n"
    $template_vm = $template_vm + "  NETWORK_UNAME = \"#{xml.xpath("//VM//TEMPLATE//NIC//NETWORK_UNAME").text}\",\n"
    $template_vm = $template_vm + "  SECURITY_GROUPS = \"#{xml.xpath("//VM//TEMPLATE//NIC//SECURITY_GROUPS").text}\""
    $template_vm = $template_vm + " ]\n"
end

def os_parse_XML(xml)    
    $template_vm = $template_vm + "OS = [\n  ARCH =  = \"#{xml.xpath("//VM//TEMPLATE/OS/ARCH").text}\",\n"
    $template_vm = $template_vm + "  BOOT =  = \"#{xml.xpath("//VM//TEMPLATE//OS//BOOT").text}\",\n"
    $template_vm = $template_vm + "  MACHINE =  = \"#{xml.xpath("//VM//TEMPLATE//OS//MACHINE").text}\""
    $template_vm = $template_vm + " ]\n"	
end

vm_name = xml.at_xpath("//VM//NAME").text
vm_pool = VirtualMachinePool.new(client, -1)
rc = vm_pool.info_search(:query    => "#{vm_name}") 
if OpenNebula.is_error?(rc)
    puts rc.message
    exit -1
end
vm_id = vm_pool.retrieve_elements('//VM//ID')
#puts vm_id[0]

if (vm_id == nil)
    $template_vm = "NAME = \"#{vm_name}\"\n"
    context_parse_XML(xml)
    cpu_parse_XML(xml)
    disk_parse_XML(xml,client)
    futures_parse_XML(xml)
    graphics_parse_XML(xml)
    user_template_parse_XML(xml)
    nic_parse_XML(xml)
    os_parse_XML(xml)
    $template_vm = $template_vm + "MEMORY =  = \"#{xml.xpath("//VM//TEMPLATE//MEMORY").text}\"\n"
    if $options[:verbose]
        puts "VM TEMPLATE:\n#{$template_vm}\n"
    end

    vm  = VirtualMachine.new(VirtualMachine.build_xml, client)
    rc = vm.allocate($template_vm)
    if OpenNebula.is_error?(rc)
        STDERR.puts rc.message
        exit(-1)
    else
        if $options[:verbose]
            puts "VM has been allocated by ID #{vm.id.to_s}"
        end 
    end
else
    puts "Error allocating a new VM. NAME \"#{vm_name}\" is already taken by VM ID #{vm_id[0]}."
	exit -1
end

exit 0
