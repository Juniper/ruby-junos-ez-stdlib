# Junos::Ez::RE::Utils

A collection of methods to access routing-engine specific functions and information.  These methods return data in Hash / Array structures so the information can be programmatically accessible, rather than scraping CLI or navigating Junos XML.

# USAGE

```ruby

# bind :re to access the routing-engine utitities
Junos::Ez::RE::Utils( ndev, :re )

# show the uptime information on this device
pp ndev.re.uptime
->
{"re0"=>
  {:time_now=>"2013-04-27 22:28:24 UTC",
   :active_users=>1,
   :load_avg=>[0.08, 0.05, 0.01],
   :uptime=>{:at=>"10:28PM", :ago=>"27 days,  2:58"},
   :time_boot=>{:at=>"2013-03-31 19:30:47 UTC", :ago=>"3w6d 02:57"},
   :protocols_started=>{:at=>"2013-03-31 19:34:53 UTC", :ago=>"3w6d 02:53"},
   :last_config=>
    {:at=>"2013-04-27 19:48:42 UTC", :ago=>"02:39:42", :by=>"jeremy"}}}
```

# METHODS

## Information

  - `status` - "show chassis routing-engine" information
  - `uptime` - "show system uptime" information
  - `system_alarms` - "show system alarms" information
  - `chassis_alarms` - "show chassis alarms" information
  - `memory` - "show system memory" information
  - `users` - "show system users" information

## Software Image

  - `validate_software?` - "request system software validate..."
  - `install_software!` - "request system software add ..."
  - `rollback_software!` - "request system software rollback"

## System Controls

  - `reboot!` - "request system reboot" (!! NO CONFIRM !!)
  - `shutdown!` - "request system power-off" (!! NO CONFIRM !!)

# GORY DETAILS

## status

Returns a Hash structure of "show chassis routing-engine" information.  Each Hash key is the RE identifier.  For example, on a target with a single RE:
```ruby
pp ndev.re.status
->
{"re0"=>
  {:model=>"JUNOSV-FIREFLY RE",
   :serialnumber=>"",
   :temperature=>{:system=>"", :cpu=>""},
   :memory=>{:total_size=>0, :buffer_util=>0},
   :cpu_util=>{:user=>0, :background=>0, :system=>2, :interrupt=>0, :idle=>98},
   :uptime=>
    {:at=>"2013-05-02 17:37:51 UTC",
     :ago=>"3 minutes, 4 seconds",
     :reboot_reason=>"Router rebooted after a normal shutdown."},
   :load_avg=>[0.06, 0.13, 0.07]}}
```

## uptime

Returns a Hash structure of "show system uptime" information.  Each Hash key is the RE identifier.  For example, on a target with a single RE:
```ruby
pp ndev.re.uptime
->
{"re0"=>
  {:time_now=>"2013-05-02 17:42:09 UTC",
   :active_users=>0,
   :load_avg=>[0.02, 0.1, 0.06],
   :uptime=>{:at=>"5:42PM", :ago=>"4 mins"},
   :time_boot=>{:at=>"2013-05-02 17:37:51 UTC", :ago=>"00:04:18"},
   :protocols_started=>{:at=>"2013-05-02 17:38:08 UTC", :ago=>"00:04:01"},
   :last_config=>
    {:at=>"2013-04-27 15:00:55 UTC", :ago=>"5d 02:41", :by=>"root"}}}
```
## system_alarms

Returns an Array of Hash structure of "show system alarms" information.  If there are no alarms, this method returns `nil`.  For example, a target with a single alarm:
```ruby
pp ndev.re.system_alarms
-> 
[{:at=>"2013-05-02 17:38:03 UTC",
  :class=>"Minor",
  :description=>"Rescue configuration is not set",
  :type=>"Configuration"}]
```

## chassis_alarms

Returns an Array Hash structure of "show chassis alarms" information.  If there are no alarms, this method returns `nil`.  For example, a target with no chassis alarms:
```ruby
pp ndev.re.chassis_alarms
->
nil
```

## memory

Returns a Hash structure of "show system memory" information

## users 

Returns a Array structure of "show system users" information.  Each Array item is a Hash structure of user information.  A target with a single user logged in would look like:
```ruby
pp ndev.re.users
-> 
[{:name=>"jeremy",
  :tty=>"p0",
  :from=>"192.168.56.1",
  :login_time=>"5:45PM",
  :idle_time=>"",
  :command=>"-cli (cli)"}]
```

## validate_software?

Performs the equivalent of "request system software validate..." and returns `true` if the software passes validation or a String indicating the error message.  The following is an example that simply checks for true:
```ruby
unless ndev.re.validate_software?( file_on_junos )
  puts "The softare does not validate!"
  ndev.close
  exit 1
end
```

## install_software! 

Performs the equivalent of "request system software add ..." and returns `true` if the operation was successful or a String indicating the error message.  The following example illustrates an error message:

```ruby
puts "Installing image ... please wait ..."
rc = ndev.re.install_software!( :package => file_on_junos, :no_validate => true )
if rc != true
  puts rc
end
```
With the results of the `rc` String:
```
Verified junos-boot-vsrx-12.1I20130415_junos_121_x44_d15.0-576602.tgz signed by PackageDevelopment_12_1_0
Verified junos-vsrx-12.1I20130415_junos_121_x44_d15.0-576602-domestic signed by PackageDevelopment_12_1_0

WARNING:     The software that is being installed has limited support.
WARNING:     Run 'file show /etc/notices/unsupported.txt' for details.

Available space: -49868 require: 4641

WARNING: The /cf filesystem is low on free disk space.
WARNING: This package requires 4641k free, but there
WARNING: is only -49868k available.

WARNING: This installation attempt will be aborted.
WARNING: If you wish to force the installation despite these warnings
WARNING: you may use the 'force' option on the command line.
ERROR: junos-12.1I20130415_junos_121_x44_d15.0-576602-domestic fails requirements check
Installation failed for package '/var/tmp/junos-vsrx-domestic.tgz'
WARNING: Not enough space in /var/tmp to unpack junos-12.1I20130415_junos_121_x44_d15.0-576602.tgz
WARNING: Use 'request system storage cleanup' and
WARNING: the 'unlink' option to improve the chances of success
```

## rollback_software!

Performs the equivalent of "request system software rollback".  The result of the operation is returned as a String.  For example, a successful rollback would look like this:
```ruby
pp ndev.re.rollback_software!
-> 
"Restoring boot file package\njunos-12.1I20130422_2129_jni-domestic will become active at next reboot\nWARNING: A reboot is required to load this software correctly\nWARNING:     Use the 'request system reboot' command\nWARNING:         when software installation is complete"
```
An unsuccessful rollback would look like this:
```ruby
pp ndev.re.rollback_software!
-> 
"WARNING: Cannot rollback, /packages/junos is not valid"
```

## reboot!( opts = {} )

Performs the "request system reboot" action.  There is **NO** confirmation prompt, so once you've executed this method, the action begins.  Once this command executes the NETCONF session to the target will eventually terminate.  You can trap the `Net::SSH::Disconnect` exception to detect this event.

The option Hash provides for the following controls:
```
:in => Fixnum
```
Instructs Junos to reboot after `:in` minutes from the time of calling `reboot!`
```
:at => String
```
Instructs Junos to reboot at a specific date and time.  The format of `:at` is YYYYMMDDHHMM, where HH is the 24-hour (military) time.  For example HH = 01 is 1am and HH=13 is 1pm.  If you omit the YYYY, MM, or DD options the current values apply.  For example `:at => 1730` is 1:30pm today.

## shutdown!( opts = {} )

Performs the "request system power-off" action.  There is **NO** confirmation prompt, so once you've executed this method, the action begins.  Once this command executes the NETCONF session to the target will eventually terminate.  You can trap the `Net::SSH::Disconnect` exception to detect this event.

The option Hash provides for the following controls:
```
:in => Fixnum
```
Instructs Junos to reboot after `:in` minutes from the time of calling `reboot!`
```
:at => String
```
Instructs Junos to reboot at a specific date and time.  The format of `:at` is YYYYMMDDHHMM, where HH is the 24-hour (military) time.  For example HH = 01 is 1am and HH=13 is 1pm.  If you omit the YYYY, MM, or DD options the current values apply.  For example `:at => 1730` is 1:30pm today.

