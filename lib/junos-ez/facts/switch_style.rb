Junos::Ez::Facts::Keeper.define( :switch_style ) do |ndev, facts|
  f_persona = uses :personality

  model = facts[:hardwaremodel]
  examine = ( model != "Virtual Chassis" ) ? model : facts.select {|k,v| k.match(/^RE[0-9]+/) }.values[0][:model]

  facts[:switch_style] = case f_persona
  when :SWITCH, :SRX_BRANCH
    case examine
    when /junosv-firefly/i
      :NONE
    when /^(?:ex9)|(?:ex43)|(?:ocx)/i
      :VLAN_L2NG
    when /^qfx/i
      if facts[:version][0..3].to_f >= 13.2
        :VLAN_L2NG
      else
        :VLAN
      end
    else
      :VLAN
    end
  when :MX, :SRX_HIGHEND
    :BRIDGE_DOMAIN
  else
    :NONE
  end
end
