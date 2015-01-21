Junos::Ez::Facts::Keeper.define( :personality ) do |ndev, facts|
  
  uses :chassis, :routingengines  
  model = facts[:hardwaremodel]

  examine = ( model != "Virtual Chassis" ) ? model : facts.select {|k,v| k.match(/^RE[0..9]+/) }.values[0][:model]
      
  facts[:personality] = case examine   
  when /^(EX)|(QFX)|(OCX)/
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
