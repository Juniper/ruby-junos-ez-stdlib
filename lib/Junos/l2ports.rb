
require "Junos/provider"

module Junos::L2ports

  PROPERTIES = [ 
    :untagged_vlan,
    :tagged_vlans,
    :vlan_tagging
  ]  

  def self.Provider( ndev, varsym )        
    
    newbie = case ndev.fact_get( :switch_style )
    when :VLAN
      Junos::L2ports::Provider::VLAN.new( ndev )      
    when :VLAN_NG
      Junos::L2ports::Provider::VLAN_NG.new( ndev )            
    when :BRIDGE_DOMAIN
      Junos::L2ports::Provider::BRIDGE_DOMAIN.new( ndev )      
    end      
    
    newbie.properties = Junos::Provider::PROPERTIES + PROPERTIES
    Junos::Provider.attach_instance_variable( ndev, varsym, newbie )
  end
  
  class Provider < Junos::Provider::Parent
  end
  
end

=begin
require 'Junos/l2ports/vlan'
require 'Junos/l2ports/vlan_l2ng'
require 'Junos/l2ports/bridge_domain'
=end


