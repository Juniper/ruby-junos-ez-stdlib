Junos::Ez::Facts::Keeper.define( :ifd_style ) do  |ndev, facts|
  persona,sw_style = uses :personality,:switch_style
  
  facts[:ifd_style] = case persona
  when :SWITCH
    if sw_style == :VLAN_L2NG
      :CLASSIC
    else
      :SWITCH
    end
  else
    :CLASSIC
  end      
  
end


