def get_image_id(image_pool,image_name)
   image_pool.each do |image|
     rc = image.info
     if OpenNebula.is_error?(rc)
          puts "IMAGE #{image.id}: #{rc.message}"
     else
	    if image.name == image_name
#          puts "IMAGE #{image.name}: #{image.state}: #{image.id}"
          return image.id 
	    end  
     end
   end
end

def get_image_pool(client)
   image_pool = ImagePool.new(client, -1)
   rc = image_pool.info
   if OpenNebula.is_error?(rc)
        puts rc.message
        exit -1
   else
      return image_pool  
   end
end