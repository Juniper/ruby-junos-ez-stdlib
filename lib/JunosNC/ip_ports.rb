
require "JunosNC/provider"

module JunosNC::IPports

  PROPERTIES = [ 
    :admin,             # [:up, :down]
    :description,       # general description text
    :tag_id,            # VLAN tag-id for vlan-tag enabled ports
    :mtu,               # MTU value as number
    :address            # ip/prefix as text, e.g. "192.168.10.22/24"
  ]  

  def self.Provider( ndev, varsym )        
    
    newbie = JunosNC::IPports::Provider::CLASSIC.new( ndev )      
    newbie.properties = JunosNC::Provider::PROPERTIES + PROPERTIES
    JunosNC::Provider.attach_instance_variable( ndev, varsym, newbie )
    
  end
  
  class Provider < JunosNC::Provider::Parent
    # common parenting goes here ...
  end
  
end

require 'JunosNC/ip_ports/classic'


