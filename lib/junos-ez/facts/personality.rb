Junos::Ez::Facts::Keeper.define( :personality ) do |ndev, facts|
  
  model = uses :hardwaremodel  
  uses :routingengines

  examine = ( model != "Virtual Chassis" ) ? model : facts[:RE0][:model]
      
  facts[:personality] = case examine   
  when /^(EX)|(QFX)/
    :SWITCH
  when /^MX/
    :MX
  when /^vMX/
    facts[:virtual] = true
    :MX
  when /SRX(\d){3}/
    :SRX_BRANCH
  when /junosv-firefly/i
    facts[:virtual] = true
    :SRX_BRANCH
  when /SRX(\d){4}/
    :SRX_HIGHEND
  end
  
end
