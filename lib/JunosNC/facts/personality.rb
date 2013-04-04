JunosNC::Facts::Keeper.define( :personality ) do
  
  model = uses :hardwaremodel  
      
  self[:personality] = case model   
  when /^(EX)|(QFX)/
    :SWITCH
  when /^MX/
    :MX
  when /^vMX/
    self[:virtual] = true
    :MX
  when /SRX(\d){3}/
    :SRX_BRANCH
  when /junosv-firefly/i
    self[:virtual] = true
    :SRX_BRANCH
  when /SRX(\d){4}/
    :SRX_HIGHEND
  end
  
end
