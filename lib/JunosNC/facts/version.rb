JunosNC::Facts::Keeper.define( :version ) do
  
  f_master, f_persona = uses :master, :personality
      
  case f_persona
  when :MX
    swver = @ndev.rpc.command "show version invoke-on all-routing-engines"
  when :SWITCH
    swver = @ndev.rpc.command "show version all-members"        
  else
    swver = @ndev.rpc.command "show version"
  end
  
  if swver.name == 'multi-routing-engine-results'
    swver_infos = swver.xpath('//software-information')
    swver_infos.each do |re_sw|
      re_name = re_sw.xpath('preceding-sibling::re-name').text.upcase
      re_sw.xpath('package-information[1]/comment').text =~ /\[(.*)\]/
      ver_key = ('version_' + re_name).to_sym
      self[ver_key] = $1                  
    end
    master_id = f_master
    self[:version] = 
      self[("version_" + "RE" + master_id).to_sym] || 
      self[('version_' + "FPC" + master_id).to_sym]
  else
    junos = swver.xpath('//package-information[name = "junos"]/comment').text
    junos =~ /\[(.*)\]/
    self[:version] = $1        
  end    
  
end
