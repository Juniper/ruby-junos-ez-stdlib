Junos::Ez::Facts::Keeper.define( :personality ) do |ndev, facts|
  uses :chassis, :routingengines

  examine = examine_model(facts[:hardwaremodel])

  facts[:personality] = case examine
  when /^(?:EX)|(?:QFX)|(?:OCX)/i
    :SWITCH
  when /^MX/i
    :MX
  when /^vMX/i
    facts[:virtual] = true
    :MX
  when /SRX(?:\d){3}/i
    :SRX_BRANCH
  when /junosv-firefly/i
    facts[:virtual] = true
    :SRX_BRANCH
  when /SRX(?:\d){4}/i
    :SRX_HIGHEND
  end
end
