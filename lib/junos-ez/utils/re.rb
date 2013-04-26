=begin
---------------------------------------------------------------------

This file contains routing-engine utility methods.  These are
a misc. collection of methods that perform basic automation tasks
like upgrading software or getting process information.  The 
following lists the methods and the equivalent Junos CLI commands

- status: show chassis routing-engine
- uptime: show system uptime
- system_alarms: show system alarms
- chassis_alarms: show chassis alarms
- memory: show system memeory
- users: show system users
- validate_software?: request system software validate
- install_software!: request system software add 
- rollback_software!: request system software rollback
- reboot!: request system reboot (no confirm!!)
- shutdown!: request system power-off (no confirm!!)
  
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
    
  ### ---------------------------------------------------------------
  ### status - show chassis routing-engine information
  ### ---------------------------------------------------------------

  def status( opts = {} )
    got = @ndev.rpc.get_route_engine_information
    status_h = {}
    got.xpath('//route-engine').each do |re|
      re_h = {}      
      slot_id = re.xpath('slot').text.to_i
      status_h[slot_id] = re_h
      
      re_h[:model] = re.xpath('model').text.strip
      re_h[:serialnumber] = re.xpath('serial-number').text.strip
      
      xml_when_item(re.xpath('mastership-state')){|i| re_h[:mastership] = i.text.strip}
      
      re_h[:temperature] = {
        :system => re.xpath('temperature').text.strip,
        :cpu => re.xpath('cpu-temperature').text.strip
      }
      re_h[:memory] = {
        :total_size => re.xpath('memory-dram-size').text.to_i,
        :buffer_util => re.xpath('memory-buffer-itilization').text.to_i
      }
      re_h[:cpu_util] = {
        :user => re.xpath('cpu-user').text.to_i,
        :background => re.xpath('cpu-background').text.to_i,
        :system => re.xpath('cpu-system').text.to_i,
        :interrupt => re.xpath('cpu-interrupt').text.to_i,
        :idle => re.xpath('cpu-idle').text.to_i,
      }
      re_h[:uptime] = {
        :at => re.xpath('start-time').text.strip,
        :ago => re.xpath('up-time').text.strip,
        :reboot_reason => re.xpath('last-reboot-reason').text.strip
      }
      re_h[:load_avg] = [
        re.xpath('load-average-one').text.to_f,
        re.xpath('load-average-five').text.to_f,
        re.xpath('load-average-fifteen').text.to_f
      ]
    end
    status_h
  end

  ### ---------------------------------------------------------------
  ### uptime - show system uptime information
  ### ---------------------------------------------------------------
  
  def uptime
    up_h = {}    
    got = @ndev.rpc.get_system_uptime_information
    unless (n_re = got.xpath('multi-routing-engine-item')).empty?
      n_re.each do |this_re|
        as_xml = this_re.xpath('system-uptime-information')
        re_name = this_re.xpath('re-name').text.strip
        up_h[re_name] = {}
        _uptime_to_h( as_xml, up_h[re_name] )
      end
    else
      up_h['re0'] = {}
      _uptime_to_h( got, up_h['re0'] )
    end
    up_h        
  end

  ### ---------------------------------------------------------------
  ### system_alarms - show system alarms
  ### ---------------------------------------------------------------
  
  def system_alarms
    got = @ndev.rpc.get_system_alarm_information
    alarms_a = []
    got.xpath('alarm-detail').each do |alarm|
      alarm_h = {}      
      _alarm_info_to_h( alarm, alarm_h )
      alarms_a << alarm_h
    end
    return nil if alarms_a.empty?
    alarms_a    
  end

  ### ---------------------------------------------------------------
  ### chassis_alarms - show chassis alarms
  ### ---------------------------------------------------------------
  
  def chassis_alarms
    got = @ndev.rpc.get_alarm_information  
    alarms_a = []
    got.xpath('alarm-detail').each do |alarm|
      alarm_h = {}
      _alarm_info_to_h( alarm, alarm_h )
      alarms_a << alarm_h
    end
    return nil if alarms_a.empty?
    alarms_a
  end

  ### ---------------------------------------------------------------
  ### memory - show system memory
  ### ---------------------------------------------------------------
  
  def memory
    got = @ndev.rpc.get_system_memory_information
    ret_h = {}
    unless (n_re = got.xpath('multi-routing-engine-item')).empty?
      n_re.each do |this_re|
        as_xml = this_re.xpath('system-memory-information')[0]
        re_name = this_re.xpath('re-name').text.strip
        ret_h[re_name] = {}
        _system_memory_to_h( as_xml, ret_h[re_name] )
      end      
    else
      ret_h['re0'] = {}
      _system_memory_to_h( got, ret_h['re0'] )      
    end
    ret_h
  end

  ### ---------------------------------------------------------------
  ### users - show system users
  ### ---------------------------------------------------------------
  
  def users
    got = @ndev.rpc.get_system_users_information
    users_h = {}
    got.xpath('uptime-information/user-table/user-entry').each do |user|
      user_h = {}
      user_name = user.xpath('user').text.strip
      user_h[:tty] = user.xpath('tty').text.strip
      user_h[:from] = user.xpath('from').text.strip
      user_h[:login_time] = user.xpath('login-time').text.strip
      user_h[:idle_time] = user.xpath('idel-time').text.strip
      user_h[:command] = user.xpath('command').text.strip
      users_h[user_name] = user_h
    end
    users_h
  end

  ### ---------------------------------------------------------------
  ### validate_software? - request system software validate ...
  ### ---------------------------------------------------------------
  
  def validate_software?( package )
    got = @ndev.rpc.request_package_validate(:package_name => package).parent
    errcode = got.xpath('package-result').text.to_i
    return true if errcode == 0
    
    # otherwise return the output error message
    got.xpath('output').text.strip    
  end

  ### ---------------------------------------------------------------
  ### install_software! - request system software add ...
  ### ---------------------------------------------------------------
  
  def install_software!( opts = {} )
    raise ArgumentError "missing :package" unless opts[:package]
    
    args = { :package_name => opts[:package] }
    args[:no_validate] = true if opts[:no_validate]
    args[:unlink] = true if opts[:unlink]
    
    got = @ndev.rpc.request_package_add( args ).parent
    errcode = got.xpath('package-result').text.to_i
    return true if errcode == 0
    
    # otherwise return the output error message
    got.xpath('output').text.strip    
  end

  ### ---------------------------------------------------------------
  ### rollback_software! - request system software rollback
  ### ---------------------------------------------------------------
  
  def rollback_software!
    got = @ndev.rpc.request_package_rollback
    got.text.strip
  end

  ### ---------------------------------------------------------------
  ### reboot! - request system reboot (no confirm!!)
  ### ---------------------------------------------------------------
  
  def reboot!( opts = {} )    
    got = @ndev.rpc.request_reboot            
    got.xpath('request-reboot-status').text.strip
  end

  ### ---------------------------------------------------------------
  ### shutdown! - request system power-off (no confirm!!)
  ### ---------------------------------------------------------------
  
  def shutdown!( opts = {} )
    ## some Junos devices will throw an RPC error exception which is really
    ## a warning, and some do not.  So we need to trap that here.
    begin
      got = @ndev.rpc.request_power_off
    rescue => e
      retmsg = e.rsp.xpath('//error-message').text.strip + "\n"  
      return retmsg + e.rsp.xpath('//request-reboot-status').text.strip
    end
    got.xpath('//request-reboot-status').text.strip
  end
  
  def ping( opts = {} )
    arg_options = [ 
      :host,
      :do_not_fragment, :inet, :inet6, :strict,      
      :count, :interface, :interval, :mac_address,
      :routing_instance, :size, :source, :tos, :ttl, :wait
    ]
    
    args = {}
    opts.each do |k,v|
      if arg_options.include? k
        args[k] = v
      else
        raise ArgumentError, "unrecognized option #{k}"
      end
    end
    
    args[:count] ||= 1
        
    got = @ndev.rpc.ping( args )
    return true if got.xpath('ping-success')[0]
    
    # if the caller privded a 'failure block' then call that now,
    # otherwise, just return false
    
    return (block_given?) ? yield(got) : false
  end
end

### -----------------------------------------------------------------
###                        PRIVATE METHODS
### -----------------------------------------------------------------

class Junos::Ez::RE::Provider
  private
  
  def _uptime_to_h( as_xml, up_h )    
    up_h[:time_now] = as_xml.xpath('current-time/date-time').text.strip
    
    data = as_xml.xpath('uptime-information')[0]    
    up_h[:active_users] = data.xpath('active-user-count').text.to_i    
    up_h[:load_avg] = [
      data.xpath('load-average-1').text.to_f,
      data.xpath('load-average-5').text.to_f,
      data.xpath('load-average-15').text.to_f,    
    ]
    up_h[:uptime] = {
      :at => data.xpath('date-time').text.strip,
      :ago => data.xpath('up-time').text.strip,    
    }
    
    data = as_xml.xpath('system-booted-time')[0]
    up_h[:time_boot] = { 
      :at => data.xpath('date-time').text.strip,
      :ago => data.xpath('time-length').text.strip
    }
    
    data = as_xml.xpath('protocols-started-time')[0]
    up_h[:protocols_started] = {
      :at => data.xpath('date-time').text.strip,
      :ago => data.xpath('time-length').text.strip      
    }
    
    data = as_xml.xpath('last-configured-time')[0]
    up_h[:last_config] = {
      :at => data.xpath('date-time').text.strip,
      :ago => data.xpath('time-length').text.strip,
      :by => data.xpath('user').text.strip      
    }    
  end  
  
  def _system_memory_to_h( as_xml, as_h )
    
    summary = as_xml.xpath('system-memory-summary-information')[0]
    as_h[:memory_summary] = {
      :total => {
        :size => summary.xpath('system-memory-total').text.to_i,
        :percentage => summary.xpath('system-memory-total-percent').text.to_i
      },
      :reserved => {
        :size => summary.xpath('system-memory-reserved').text.to_i,
        :percentage => summary.xpath('system-memory-reserved-percent').text.to_i      
      },
      :wired => {
        :size => summary.xpath('system-memory-wired').text.to_i,
        :percentage => summary.xpath('system-memory-wired-percent').text.to_i            
      },
      :active => {
        :size => summary.xpath('system-memory-active').text.to_i,
        :percentage => summary.xpath('system-memory-active-percent').text.to_i                  
      },
      :inactive => {
        :size => summary.xpath('system-memory-inactive').text.to_i,
        :percentage => summary.xpath('system-memory-inactive-percent').text.to_i                  
      },
      :cache => {
        :size => summary.xpath('system-memory-cache').text.to_i,
        :percentage => summary.xpath('system-memory-cache-percent').text.to_i                  
      },
      :free => {
        :size => summary.xpath('system-memory-free').text.to_i,
        :percentage => summary.xpath('system-memory-free-percent').text.to_i                  
      }
    }
    
    as_h[:procs] = {}
    as_xml.xpath('pmap-terse-information/pmap-terse-summary').each do |proc|
      proc_h = {}
      proc_name = proc.xpath('map-name | process-name').text.strip
      as_h[:procs][proc_name] = proc_h
      
      proc_h[:pid] = proc.xpath('pid').text.to_i
      proc_h[:size] = proc.xpath('size').text.to_i
      proc_h[:size_pct] = proc.xpath('size-percent').text.to_f
      proc_h[:resident] = proc.xpath('resident').text.to_i
      proc_h[:resident_pct] = proc.xpath('resident-percent').text.to_f
    end    
  end
  
  def _alarm_info_to_h( alarm, alarm_h )
    alarm_h[:at] = alarm.xpath('alarm-time').text.strip
    alarm_h[:class] = alarm.xpath('alarm-class').text.strip
    alarm_h[:description] = alarm.xpath('alarm-description').text.strip
    alarm_h[:type] = alarm.xpath('alarm-type').text.strip
  end
end
