# Routing-Engine Utilities

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

# UTILITY METHODS

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
