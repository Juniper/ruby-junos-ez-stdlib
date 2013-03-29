Junos::Facts::Keeper.define( :chassis ) do
  
  inv_info = @ndev.rpc.get_chassis_inventory
  chassis = inv_info.xpath('chassis')
  
  @facts[:hardwaremodel] = chassis.xpath('description').text
  @facts[:serialnumber] = chassis.xpath('serial-number').text           
end

Junos::Facts::Keeper.define( :routingengines ) do

  re_facts = ['mastership-state','status','model','up-time','last-reboot-reason']
  re_info = @ndev.rpc.get_route_engine_information
  re_info.xpath('//route-engine').each do |re|
    slot_id = re.xpath('slot').text
    slot = ("RE" + slot_id).to_sym
    @facts[slot] = Hash[ re_facts.collect{ |ele| [ ele.tr('-','_').to_sym, re.xpath(ele).text ] } ]
    @facts[:master] = slot_id if @facts[slot][:mastership_state] == 'master'
  end
  
end

        

