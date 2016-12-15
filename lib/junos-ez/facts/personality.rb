Junos::Ez::Facts::Keeper.define( :personality ) do |ndev, facts|
  uses :chassis, :routingengines
  model = facts[:hardwaremodel]

  examine = nil
  if model == 'Virtual Chassis'
    re = facts.detect {|k,v| k.match(/^RE\d+/)}
    if re
      re_model = re[1][:model]
      if re_model
        examine = re_model.start_with?('RE-') ? re_model[3, re_model.length] : re_model
      end
    end
  else
    examine = model
  end

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
