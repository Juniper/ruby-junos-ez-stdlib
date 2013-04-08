
require "junos-ez/provider"

module Junos::Ez::L2ports

  PROPERTIES = [ 
    :untagged_vlan,
    :tagged_vlans,
    :vlan_tagging
  ]  

  def self.Provider( ndev, varsym )        
    
    newbie = case ndev.fact( :switch_style )
    when :VLAN
      Junos::Ez::L2ports::Provider::VLAN.new( ndev )      
    when :VLAN_NG
      Junos::Ez::L2ports::Provider::VLAN_NG.new( ndev )            
    when :BRIDGE_DOMAIN
      Junos::Ez::L2ports::Provider::BRIDGE_DOMAIN.new( ndev )      
    end      
    
    newbie.properties = Junos::Ez::Provider::PROPERTIES + PROPERTIES
    Junos::Ez::Provider.attach_instance_variable( ndev, varsym, newbie )
  end
  
  class Provider < Junos::Ez::Provider::Parent
  end
  
end

=begin
require 'junos-ez/l2ports/vlan'
require 'junos-ez/l2ports/vlan_l2ng'
require 'junos-ez/l2ports/bridge_domain'
=end


