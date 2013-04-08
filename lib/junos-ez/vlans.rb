require "junos-ez/provider"

module Junos::Ez::Vlans

  PROPERTIES = [
     :vlan_id, 
     :description, 
     :no_mac_learning
  ]  

  def self.Provider( ndev, varsym )        
    newbie = case ndev.fact_get(:switch_style)
    when :VLAN, :VLAN_NG
      Junos::Ez::Vlans::Provider::VLAN.new( ndev )
    when :BRIDGE_DOMAIN
      Junos::Ez::Vlans::Provider::BRIDGE_DOMAIN.new( ndev )      
    end      
    newbie.properties = Junos::Ez::Provider::PROPERTIES + PROPERTIES
    Junos::Ez::Provider.attach_instance_variable( ndev, varsym, newbie )
  end
  
  class Provider < Junos::Ez::Provider::Parent
    # common parenting goes here ...
  end
  
end

require 'junos-ez/vlans/vlan'
require 'junos-ez/vlans/bridge_domain'


