
def server_array_to_cat( sa, rname )

    puts "  ServerArray: " + sa.name
    str = ""

    # Some of the basic resource information
    str += "resource '"+rname+"', type: 'server_array' do\n"
    str += "  name '"+sa.name.gsub(/\'/,"\\\\'")+"'\n"
    if !sa.description.nil? 
      str += "  description '"+sa.description.gsub(/\'/,"\\\\'")+"'\n"
    end

    # Get the instance information and the ServerTemplate details
    ni = sa.show.next_instance.show(:view=>"full")

    str += instance_details_to_cat(ni)

    if sa.raw["optimized"]
      str += "  optimized '"+sa.optimized+"'\n"
    end
    
    if sa.raw["state"]
      str += "  state '"+sa.state+"'\n"
    end
    
    str += "  elasticity_params do\n"
    str += "    { 'min_count'            => "+sa.elasticity_params["bounds"]["min_count"]+",\n"
    str += "      'max_count'            => "+sa.elasticity_params["bounds"]["max_count"]+",\n"
    str += "      'resize_calm_time'     => "+sa.elasticity_params["pacing"]["resize_calm_time"]+",\n"
    str += "      'resize_down_by'       => "+sa.elasticity_params["pacing"]["resize_down_by"]+",\n"
    str += "      'resize_up_by'         => "+sa.elasticity_params["pacing"]["resize_up_by"]+",\n"
    str += "      'decision_threshold'   => "+sa.elasticity_params["alert_specific_params"]["decision_threshold"]+",\n"
    str += "      'voters_tag_predicate' => '"+sa.elasticity_params["alert_specific_params"]["voters_tag_predicate"]+"' }\n"
    str += "  end\n"

    str += "end\n"
    str
end

def server_to_cat( s, rname )

    puts "  Server: " + s.name

    str = ""
    # Some of the basic resource information
    str += "resource '"+rname+"', type: 'server' do\n"
    str += "  name '"+s.name.gsub(/\'/,"\\\\'")+"'\n"
    if !s.description.nil? 
      str += "  description '"+s.description.gsub(/\'/,"\\\\'")+"'\n"
    end

    # Get the instance information and the ServerTemplate details
    ni = s.show.next_instance.show(:view=>"full")

    str += instance_details_to_cat(ni)

    if s.raw["optimized"]
      str += "  optimized '"+s.optimized+"'\n"
    end
    
    str += "end\n"
    str
end


def instance_details_to_cat( ni )

    st = ni.server_template.show(:view=>"inputs_2_0")

    str = ""
    str += "  cloud '"+ni.cloud.show.name.gsub(/\'/,"\\\\'")+"'\n"
    
    # Check to see if there is a datacenter link to export
    if !ni.raw["links"].detect{ |l| l["rel"] == "datacenter" && l["inherited_source"] == nil}.nil?
      str += "  datacenter '"+ni.datacenter.show.name.gsub(/\'/,"\\\\'")+"'\n"
    end

    # Check to see if there is a image link to export
    if !ni.raw["links"].detect{ |l| l["rel"] == "image" && l["inherited_source"] == nil}.nil?
      str += "  image '"+ni.image.show.name.gsub(/\'/,"\\\\'")+"'\n"
    end

    # Check to see if there is an instance type link to export
    if !ni.raw["links"].detect{ |l| l["rel"] == "instance_type" && l["inherited_source"] == nil}.nil?
      str += "  instance_type '"+ni.instance_type.show.name.gsub(/\'/,"\\\\'")+"'\n"
    end 

    # Check to see if there is an kernel type link to export
    if !ni.raw["links"].detect{ |l| l["rel"] == "kernel_type" && l["inherited_source"] == nil}.nil?
      str += "  kernel_type '"+ni.kernel_type.show.name.gsub(/\'/,"\\\\'")+"'\n"
    end 

    # Check to see if there is an multi cloud image link to export
    if !ni.raw["links"].detect{ |l| l["rel"] == "multi_cloud_image" && l["inherited_source"] == nil}.nil?
      str += "  multi_cloud_image '"+ni.multi_cloud_image.show.name.gsub(/\'/,"\\\\'")+"'\n"
    end 

    # Check to see if there is an multi cloud image link to export
    if !ni.raw["links"].detect{ |l| l["rel"] == "ramdisk_image" && l["inherited_source"] == nil}.nil?
      str += "  ramdisk_image '"+ni.ramdisk_image.show.name.gsub(/\'/,"\\\\'")+"'\n"
    end 

    if !ni.user_data.nil?
      str += "  user_data '"+ni.user_data.gsub(/\'/,"\\\\'")+"'\n"
    end

    # Check to see if there is a subnets link
    # Note: this will never be populated using existing right_api_client (1.5.15) gem
    #  This is only populated using a hacked r_a_c 
    #  The hack may return a single subnets link, or an array of links, so we have to check for that
    if !ni.raw["links"].detect{ |l| l["rel"] == "subnets"}.nil?
      str += "  subnets "
      if ni.subnets.kind_of?(Array)
        ni.subnets.each_with_index do |s,i|
          str += "'"+s.show.name.gsub(/\'/,"\\\\'")+"'"
          if i+1 != ni.subnets.size
            str += ", "
          end
        end
      else
        str += "'"+ni.subnets.show.name.gsub(/\'/,"\\\\'")+"'"
      end
      str += "\n"
    end 

    # Check to see if there is a security_groups link
    # Note: this will never be populated using existing right_api_client (1.5.15) gem
    #  This is only populated using a hacked r_a_c 
    #  The hack may return a single security_groups link, or an array of links, so we have to check for that
    if !ni.raw["links"].detect{ |l| l["rel"] == "security_groups"}.nil?
      str += "  security_groups "
      if ni.security_groups.kind_of?(Array)
        ni.security_groups.each_with_index do |s,i|
          str += "'"+s.show.name.gsub(/\'/,"\\\\'")+"'"
          if i+1 != ni.security_groups.size
            str += ", "
          end
        end
      else
        str += "'"+ni.security_groups.show.name.gsub(/\'/,"\\\\'")+"'"
      end
      str += "\n"
    end 

    # Output the server template information
    str += "  server_template find('"+st.name.gsub(/\'/,"\\\\'")+"', revision: "+st.revision.to_s()+")\n"

    # For each input, check to see if this input is in the ServerTemplate with the same value
    #  If so, skip it, since it appears to be inherited anyway
    inputs = ni.inputs.index(:view=>"inputs_2_0")
    str += "  inputs do {\n"
    inputs.each do |i|
      if st.raw["inputs"].find{ |sti| sti["name"] == i.name && sti["value"] == i.value }.nil?  
        str += "    '"+i.name+"' => '"+i.value.gsub(/\'/,"\\\\'")+"',\n"
      end
    end 
    str += "  } end\n"

    str
end

def deployment_to_cat_file( client, deployment_id )

# Get and show the deployment name
dep = client.deployments(:id=>deployment_id).show
puts "Exporting Deployment: " + dep.name

# Output to a file named after the deployment (cleaned up for Linux filenames)
File.open(dep.name.gsub(/[^\w\s_-]+/, '')+'.cat','w') do |f|

  # Output the metadata of this CloudApp
  f.puts "name '"+dep.name.gsub(/\'/,"\\\\'")+"'"
  f.puts "rs_ca_ver 20131202"
  f.puts "short_description '"+dep.description.gsub(/\'/,"\\\\'")+"'"

  # For each Server in the deployment (regardless of its status)
  servers = dep.servers.index
  scount = 0
  servers.each do |s|

    rname = "server_"+(scount+=1).to_s
    f.puts(server_to_cat(s, rname))

  end

  serverarrays = dep.server_arrays.index
  scount = 0
  serverarrays.each do |sa|

    rname = "server_array_"+(scount+=1).to_s
    f.puts(server_array_to_cat(sa, rname))

  end
end

end
