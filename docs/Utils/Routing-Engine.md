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

Returns a Hash structure of "show system alarms" information

## chassis_alarms

Returns a Hash structure of "show chassis alarms" information

## memory

Returns a Hash structure of "show system memory" information

## users 

Returns a Hash structure of "show system users" information

## validate_software?

Performs the equivalent of "request system software validate..." and returns `true` if the software passes validation or a ...

## install_software! 

Performs the equivalent of "request system software add ..." and returns `true` if the operation was successful or ...

## rollback_software!

Performs the equivalent of "request system software rollback"

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

