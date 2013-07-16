
require "junos-ez/provider"
require 'junos-ez/system/st_hosts'
require 'junos-ez/system/st_routes'
require 'junos-ez/system/users'
require 'junos-ez/system/userauths'

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




