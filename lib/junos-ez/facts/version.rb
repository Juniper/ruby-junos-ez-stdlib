Junos::Ez::Facts::Keeper.define( :version ) do |ndev, facts|
  
  f_master, f_persona = uses :master, :personality
      
  case f_persona
  when :MX
    begin
      swver = ndev.rpc.command "show version invoke-on all-routing-engines"
    rescue Netconf::RpcError
      swver = ndev.rpc.command "show version"
    end
  when :SWITCH
    ## most EX switches support the virtual-chassis feature, so the 'all-members' option would be valid
    ## in some products, this options is not valid (i.e. not vc-capable.  so we're going to try for vc, and if that
    ## throws an exception we'll rever to non-VC
    
    begin
      swver = ndev.rpc.command "show version all-members"
    rescue Netconf::RpcError
      facts[:vc_capable] = false
      swver = ndev.rpc.command "show version"
    else
      facts[:vc_capable] = true
    end
  else
    swver = ndev.rpc.command "show version"
  end
  
  if swver.name == 'multi-routing-engine-results'
    swver_infos = swver.xpath('//software-information')
    swver_infos.each do |re_sw|
      re_name = re_sw.xpath('preceding-sibling::re-name').text.upcase
      ver_key = ('version_' + re_name).to_sym
      
      if re_sw.at_xpath('//junos-version')
        facts[ver_key] = re_sw.xpath('//junos-version').text
      else
        re_sw.xpath('package-information[1]/comment').text =~ /\[(.*)\]/
        facts[ver_key] = $1
      end	
    end
    master_id = f_master
    unless master_id.nil?
      facts[:version] = 
        facts[("version_" + "RE" + master_id).to_sym] || 
        facts[('version_' + "FPC" + master_id).to_sym]
    end
  else
    if swver.at_xpath('//junos-version')
      facts[:version] = swver.xpath('//junos-version').text
    else
      junos = swver.xpath('//package-information[name = "junos"]/comment').text
      junos =~ /\[(.*)\]/
      facts[:version] = $1
    end  
  end    
  
end
