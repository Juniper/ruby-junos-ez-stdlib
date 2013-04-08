
require "junos-ez/provider"

module Junos::Ez::Hosts
  
  PROPERTIES = [
    :ip,                    # ipv4 address :String
    :ip6,                   # ipv6 address :String
  ]
  
  def self.Provider( ndev, varsym )            
    newbie = Junos::Ez::Hosts::Provider.new( ndev )      
    newbie.properties = Junos::Ez::Provider::PROPERTIES + PROPERTIES
    Junos::Ez::Provider.attach_instance_variable( ndev, varsym, newbie )    
  end  
  
  class Provider < Junos::Ez::Provider::Parent
  end
  
end

require 'junos-ez/system/hosts'
  
module Junos::Ez::StaticRoutes
  
    PROPERTIES = [
      :gateway,             # next-hop gateway, could be single or Array
      :metric,              # number or nil
      :action,              # one-of [ :reject, :discard, :receive ]
      :active,              # flag [ true, nil | false ]
      :retain,              # no-flag [ nil, true, false ]
      :install,             # no-flag [ nil, true, false ]
      :readvertise,         # no-flag [ nil, true, false ]
      :resolve,             # no-flag [ nil, true, false ]
    ]
    
  def self.Provider( ndev, varsym )            
    newbie = Junos::Ez::StaticRoutes::Provider.new( ndev )      
    newbie.properties = Junos::Ez::Provider::PROPERTIES + PROPERTIES
    Junos::Ez::Provider.attach_instance_variable( ndev, varsym, newbie )    
  end  
  
  class Provider < Junos::Ez::Provider::Parent
  end
    
end

require 'junos-ez/system/stroutes'




