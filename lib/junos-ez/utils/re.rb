=begin
---------------------------------------------------------------------

This file contains routing-engine utility methods.  These are
a misc. collection of methods that perform basic automation tasks
like upgrading software or getting process information
  
---------------------------------------------------------------------
=end

module Junos::Ez::RE
  def self.Utils( ndev, varsym )            
    newbie = Junos::Ez::RE::Provider.new( ndev )      
    Junos::Ez::Provider.attach_instance_variable( ndev, varsym, newbie )    
  end          
end

### -----------------------------------------------------------------
###                        PUBLIC METHODS
### -----------------------------------------------------------------
### class containing filesystem public utility functions
### these are not in alphabetical order, but I should do that, yo!
### -----------------------------------------------------------------

class Junos::Ez::RE::Provider < Junos::Ez::Provider::Parent
    
  def alarms
  end
  
  def memory
  end
  
  def users
  end
  
  def validate_software?( package )
    got = @ndev.rpc.request_package_validate(:package_name => package).parent
    errcode = got.xpath('package-result').text.to_i
    return true if errcode == 0
    
    # otherwise return the output error message
    got.xpath('output').text.strip    
  end
  
  def install_software!( opts = {} )
    raise ArgumentError "missing :package" unless opts[:package]
    
    args = {:package_name => opts[:package]}
    args[:no_validate] = true if opts[:no_validate]
    args[:unlink] = true if opts[:unlink]
    
    got = @ndev.rpc.request_package_add( args ).parent
    errcode = got.xpath('package-result').text.to_i
    return true if errcode == 0
    
    # otherwise return the output error message
    got.xpath('output').text.strip    
  end
  
  def rollback_software!
    got = @ndev.rpc.request_package_rollback
    got.text.strip
  end
  
  def reboot!( opts = {} )    
    got = @ndev.rpc.request_reboot
    got.xpath('request-reboot-status').text.strip
  end
  
  def shutdown!( opts = {} )
    
  end
  
end
