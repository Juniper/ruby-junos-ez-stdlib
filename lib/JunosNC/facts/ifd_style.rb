
JunosNC::Facts::Keeper.define( :ifd_style ) do 
  persona = uses :personality
  
  self[:ifd_style] = case persona
  when :SWITCH
    :SWITCH
  else
    :CLASSIC
  end      
  
end


