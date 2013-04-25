
require "junos-ez/provider"

### -----------------------------------------------------------------
### manage static host entries, kinda like "/etc/hosts"
### -----------------------------------------------------------------

module Junos::Ez::StaticHosts
  
  PROPERTIES = [
    :ip,                    # ipv4 address :String
    :ip6,                   # ipv6 address :String
  ]
  
  def self.Provider( ndev, varsym )            
    newbie = Junos::Ez::StaticHosts::Provider.new( ndev )      
    newbie.properties = Junos::Ez::Provider::PROPERTIES + PROPERTIES
    Junos::Ez::Provider.attach_instance_variable( ndev, varsym, newbie )    
  end  
  
  class Provider < Junos::Ez::Provider::Parent
  end
  
end

require 'junos-ez/system/st_hosts'

### -----------------------------------------------------------------
### manage static route entries
### -----------------------------------------------------------------

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

require 'junos-ez/system/st_routes'

### -----------------------------------------------------------------
### the 'syscfg' is a work in progress, do not use ...
### -----------------------------------------------------------------

module Junos::Ez::SysConfig
  
  PROPERTIES = [
    :host_name,             # String, host-name
    :domain_name,           # domain name, string or array
    :domain_search,         # array of dns name suffix values
    :dns_servers,           # array of ip-addrs
    :ntp_servers,           # array NTP servers HASH of
                            #   :version
                            #   :key
    :timezone,              # String time-zone
    :date,                  # String format: YYYYMMDDhhmm.ss
    :location,              # location HASH with properties
                            #   :countrycode
                            #   :building,
                            #   :floor,
                            #   :rack
  ]
  
  def self.Provider( ndev, varsym )            
    raise ArgumentError "work-in-progress ..."
    
    newbie = Junos::Ez::SysConfig::Provider.new( ndev )      
    newbie.properties = Junos::Ez::Provider::PROPERTIES + PROPERTIES
    Junos::Ez::Provider.attach_instance_variable( ndev, varsym, newbie )    
  end  
  
  class Provider < Junos::Ez::Provider::Parent
  end
    
end

require 'junos-ez/system/syscfg'




