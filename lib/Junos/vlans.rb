
require "Junos/provider"

module Junos::Vlans

  PROPERTIES = [:vlan_id, :description, :no_mac_learning]  

  def self.Provider( ndev, varsym )        
    newbie = case ndev.fact_get(:switch_style)
    when :VLAN, :VLAN_NG
      Junos::Vlans::Provider::VLAN.new( ndev )
    when :BRIDGE_DOMAIN
      Junos::Vlans::Provider::BRIDGE_DOMAIN.new( ndev )      
    end      
    newbie.properties = Junos::Provider::PROPERTIES + PROPERTIES
    Junos::Provider.attach_instance_variable( ndev, varsym, newbie )
  end
  
  class Provider < Junos::Provider::Parent
  end
  
end

require 'Junos/vlans/vlan'
require 'Junos/vlans/bridge_domain'


