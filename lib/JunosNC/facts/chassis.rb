JunosNC::Facts::Keeper.define( :chassis ) do
  
  inv_info = @ndev.rpc.get_chassis_inventory
  chassis = inv_info.xpath('chassis')
  
  self[:hardwaremodel] = chassis.xpath('description').text
  self[:serialnumber] = chassis.xpath('serial-number').text           
end

JunosNC::Facts::Keeper.define( :master ) do
  uses :routingengines
end

JunosNC::Facts::Keeper.define( :routingengines ) do

  re_facts = ['mastership-state','status','model','up-time','last-reboot-reason']
  re_info = @ndev.rpc.get_route_engine_information
  re_info.xpath('//route-engine').each do |re|
    slot_id = re.xpath('slot').text || "0"
    slot = ("RE" + slot_id).to_sym
    self[slot] = Hash[ re_facts.collect{ |ele| [ ele.tr('-','_').to_sym, re.xpath(ele).text ] } ]
    self[:master] = slot_id if self[slot][:mastership_state] == 'master'
  end
  
end

        

