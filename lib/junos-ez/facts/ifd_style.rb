
Junos::Ez::Facts::Keeper.define( :ifd_style ) do  |ndev, facts|
  persona = uses :personality
  
  facts[:ifd_style] = case persona
  when :SWITCH
    :SWITCH
  else
    :CLASSIC
  end      
  
end


