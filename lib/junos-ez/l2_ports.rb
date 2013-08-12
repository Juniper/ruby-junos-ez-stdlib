
require "junos-ez/provider"

module Junos::Ez::L2ports

  PROPERTIES = [ 
    :description,           # String | nil
    :untagged_vlan,         # String | nil
    :tagged_vlans,          # Set of String | nil
    :vlan_tagging           # true | false
  ]  

  def self.Provider( ndev, varsym )        
    
    newbie = case ndev.fact( :switch_style )
    when :VLAN
      Junos::Ez::L2ports::Provider::VLAN.new( ndev )      
    when :VLAN_L2NG
      Junos::Ez::L2ports::Provider::VLAN_L2NG.new( ndev )            
    when :BRIDGE_DOMAIN
      raise ArgumentError, "under development"
#      Junos::Ez::L2ports::Provider::BRIDGE_DOMAIN.new( ndev )      
    end      
    
    newbie.properties = Junos::Ez::Provider::PROPERTIES + PROPERTIES
    Junos::Ez::Provider.attach_instance_variable( ndev, varsym, newbie )
  end
  
  class Provider < Junos::Ez::Provider::Parent
    # common parenting ...
    
    def is_trunk?
      @has[:vlan_tagging] == true
    end
    
    def should_trunk?
      (@should[:vlan_tagging].nil?) ? @has[:vlan_tagging] : @should[:vlan_tagging]
    end
    
    def mode_changed?
      return true if is_new?
      return false if @should[:vlan_tagging].nil?      
      @should[:vlan_tagging] != @has[:vlan_tagging]      
    end    
    
  end
  
end

require 'junos-ez/l2_ports/vlan'
require 'junos-ez/l2_ports/vlan_l2ng'

# require 'junos-ez/l2ports/bridge_domain' ... under development


