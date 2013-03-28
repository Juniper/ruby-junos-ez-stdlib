Junos::Facts::Keeper.define( :switch_style ) do
  f_persona = uses :personality
    
  @facts[:switch_style] = case f_persona
  when :SWITCH, :SRX_BRANCH
    case @facts[:hardwaremodel]
    when /^(ex9)|(ex43)/
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
    

