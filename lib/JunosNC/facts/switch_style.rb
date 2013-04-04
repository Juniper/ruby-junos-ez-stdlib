JunosNC::Facts::Keeper.define( :switch_style ) do
  f_persona = uses :personality
    
  self[:switch_style] = case f_persona
  when :SWITCH, :SRX_BRANCH
    case self[:hardwaremodel]
    when /junosv-firefly/i
      :NONE
    when /^(ex9)|(ex43)/i
      :VLAN_L2NG
    else
      :VLAN
    end        
  when :MX, :SRX_HIGHEND
    :BRIDGE_DOMAIN
  else
    :NONE
  end

end
    

