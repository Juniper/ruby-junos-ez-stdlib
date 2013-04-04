require "JunosNC/provider"

module JunosNC::Vlans

  PROPERTIES = [
     :vlan_id, 
     :description, 
     :no_mac_learning
  ]  

  def self.Provider( ndev, varsym )        
    newbie = case ndev.fact_get(:switch_style)
    when :VLAN, :VLAN_NG
      JunosNC::Vlans::Provider::VLAN.new( ndev )
    when :BRIDGE_DOMAIN
      JunosNC::Vlans::Provider::BRIDGE_DOMAIN.new( ndev )      
    end      
    newbie.properties = JunosNC::Provider::PROPERTIES + PROPERTIES
    JunosNC::Provider.attach_instance_variable( ndev, varsym, newbie )
  end
  
  class Provider < JunosNC::Provider::Parent
    # common parenting goes here ...
  end
  
end

require 'JunosNC/vlans/vlan'
require 'JunosNC/vlans/bridge_domain'


