
require 'Junos/junosmod'
require "Junos/provides"

module Junos::Vlans
   
  PROPERTIES = [:vlan_id, :description, :no_mac_learning]
            
  def self.Provider( ndev, varsym )    
    
    newbie = case ndev.fact_get(:switch_style)
    when :VLAN, :VLAN_NG
      Junos::Vlans::VLAN.new( ndev )
    when :BRIDGE_DOMAIN
      Junos::Vlans::BRIDGE_DOMAIN.new( ndev )      
    end      
    
    newbie.properties = Junos::Provides::PROPERTIES + PROPERTIES
    Junos.dynvar( ndev, varsym, newbie )    
  end
  
end

require 'Junos/vlans/vlan'
require 'Junos/vlans/bridge_domain'


