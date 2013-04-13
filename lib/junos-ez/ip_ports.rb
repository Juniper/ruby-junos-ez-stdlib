
require "junos-ez/provider"

module Junos::Ez::IPports

  PROPERTIES = [ 
    :admin,             # [:up, :down]
    :description,       # general description text
    :tag_id,            # VLAN tag-id for vlan-tag enabled ports
    :mtu,               # MTU value as number
    :address            # ip/prefix as text, e.g. "192.168.10.22/24"
  ]  

  def self.Provider( ndev, varsym )            
    newbie = Junos::Ez::IPports::Provider::CLASSIC.new( ndev )      
    newbie.properties = Junos::Ez::Provider::PROPERTIES + PROPERTIES
    Junos::Ez::Provider.attach_instance_variable( ndev, varsym, newbie )    
  end
  
  class Provider < Junos::Ez::Provider::Parent
    # common parenting goes here ...
  end
  
end

require 'junos-ez/ip_ports/classic'


