Junos::Ez::Facts::Keeper.define( :chassis ) do |ndev, facts|
  
  inv_info = ndev.rpc.get_chassis_inventory
  errs = inv_info.xpath('//output')[0]

  if errs and errs.text.include? "This command can only be used on the master routing engine"
     raise Junos::Ez::NoProviderError, "Chef can only be used on master routing engine !!"
  end

  chassis = inv_info.xpath('chassis')
  
  facts[:hardwaremodel] = chassis.xpath('description').text
  facts[:serialnumber] = chassis.xpath('serial-number').text           
  
  cfg = ndev.rpc.get_configuration{|xml|
    xml.system {
      xml.send(:'host-name')
      xml.send(:'domain-name')
    }
  }
  
  facts[:hostname] = cfg.xpath('//host-name').text
  facts[:domain] = cfg.xpath('//domain-name').text
  facts[:fqdn] = facts[:hostname]
  facts[:fqdn] += ".#{facts[:domain]}" unless facts[:domain].empty?
  
end

Junos::Ez::Facts::Keeper.define( :master ) do |ndev, facts|
  uses :routingengines
end

Junos::Ez::Facts::Keeper.define( :routingengines ) do |ndev, facts|

  re_facts = ['mastership-state','status','model','up-time','last-reboot-reason']
  re_info = ndev.rpc.get_route_engine_information
  re_info.xpath('//route-engine').each do |re|
    slot_id = re.xpath('slot').text || "0"
    slot = ("RE" + slot_id).to_sym
    facts[slot] = Hash[ re_facts.collect{ |ele| [ ele.tr('-','_').to_sym, re.xpath(ele).text ] } ]
    if facts[slot][:mastership_state].empty?
      facts[slot].delete :mastership_state
    else 
      facts[:master] = slot_id if facts[slot][:mastership_state] == 'master'
    end
  end
  
end

        

