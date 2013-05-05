# `Junos::Ez::RE::Utils`

A collection of methods to access routing-engine specific functions and information.  These methods return data in Hash / Array structures so the information can be programmatically accessible.

# METHODS

## Informational

  - [`status`](#status) - "show chassis routing-engine" information
  - [`uptime`](#uptime) - "show system uptime" information
  - [`system_alarms`](#system_alarms) - "show system alarms" information
  - [`chassis_alarms`](#chassis_alarms) - "show chassis alarms" information
  - [`memory`](#memory) - "show system memory" information
  - [`users`](#users) - "show system users" information

## Software Image

  - [`software_validate?`](#software_validate) - "request system software validate..."
  - [`software_install!`](#software_install) - "request system software add ..."
  - [`software_rollback!`](#software_rollback) - "request system software rollback"
  - [`software_images`](#software_images) - indicates current/rollback image file names

## License Management

  - [`license_install!`](#license_install) - "request system license add"
  - [`license_rm!`](#license_rm) - "request system license delete"
  - [`licenses`](#licenses) - "show system license"

## System Controls

  - [`reboot!`](#reboot) - "request system reboot" (!! NO CONFIRM !!)
  - [`shutdown!`](#shutdown) - "request system power-off" (!! NO CONFIRM !!)

## Miscellaneous

  - [`ping`](#ping) - Perform a "ping" command

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



# GORY DETAILS

## `status`

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

## `uptime`

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
## `system_alarms`

Returns an Array of Hash structure of "show system alarms" information.  If there are no alarms, this method returns `nil`.  For example, a target with a single alarm:
```ruby
pp ndev.re.system_alarms
-> 
[{:at=>"2013-05-02 17:38:03 UTC",
  :class=>"Minor",
  :description=>"Rescue configuration is not set",
  :type=>"Configuration"}]
```

## `chassis_alarms`

Returns an Array Hash structure of "show chassis alarms" information.  If there are no alarms, this method returns `nil`.  For example, a target with no chassis alarms:
```ruby
pp ndev.re.chassis_alarms
->
nil
```

## `memory`

Returns a Hash structure of "show system memory" information.  Each key is the RE indentifier.  A target with a single RE would look like the following.  Note that the `:procs` Array is the process array, with each element as a Hash of process specific information.
```ruby
pp ndev.re.memory
-> 
{"re0"=>
  {:memory_summary=>
    {:total=>{:size=>1035668, :percentage=>100},
     :reserved=>{:size=>18688, :percentage=>1},
     :wired=>{:size=>492936, :percentage=>47},
     :active=>{:size=>184152, :percentage=>17},
     :inactive=>{:size=>65192, :percentage=>6},
     :cache=>{:size=>261140, :percentage=>25},
     :free=>{:size=>12660, :percentage=>1}},
   :procs=>
    [{:name=>"kernel",
      :pid=>0,
      :size=>569704,
      :size_pct=>54.49,
      :resident=>90304,
      :resident_pct=>8.71},
     {:name=>"/sbin/pmap",
      :pid=>2768,
      :size=>4764,
      :size_pct=>0.15,
      :resident=>1000,
      :resident_pct=>0.09},
     {:name=>"file: (mgd) /proc/2766/file (jeremy)",
      :pid=>2765,
      :size=>727896,
      :size_pct=>23.16,
      :resident=>18904,
      :resident_pct=>1.82},
      #
      # snip, omitted full array for sake of sanity ...
      #
    ]}}
```

## `users` 

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

## `software_images`
Returns a Hash of the currnet and rollback image file-names.
```ruby
pp ndev.re.software_images
-> 
{:rollback=>"junos-12.1I20130415_junos_121_x44_d15.0-576602-domestic",
 :current=>"junos-12.1I20130322_2104_slt-builder-domestic"}
```

## `software_validate?` <a name="software_validate">

Performs the equivalent of "request system software validate..." and returns `true` if the software passes validation or a String indicating the error message.  The following is an example that simply checks for true:
```ruby
unless ndev.re.software_validate?( file_on_junos )
  puts "The softare does not validate!"
  ndev.close
  exit 1
end
```

## `software_install!( opts = {} )` <a name="software_install">

Performs the equivalent of "request system software add ..." and returns `true` if the operation was successful or a String indicating the error message.  

The following options are supported:
```
:no_validate => true
```
Instructs Junos not to validate the software image.  You should use this option if your program explicity calls `software_validate?` first, since you don't want to do the validation twice.
```
:unlink => true
```
Instructs Junos to remove the software package file (.tgz) after the installation has completed. 
```
:reboot => true
```
Instructs Junos to reboot the RE after the software has been installed successfully.

The following example illustrates an error message:

```ruby
puts "Installing image ... please wait ..."
rc = ndev.re.software_install!( :package => file_on_junos, :no_validate => true )
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

## `software_rollback!` <a name="software_rollback">

Performs the equivalent of "request system software rollback".  The result of the operation is returned as a String.  For example, a successful rollback would look like this:
```ruby
pp ndev.re.software_rollback!
-> 
"Restoring boot file package\njunos-12.1I20130415_junos_121_x44_d15.0-576602-domestic will become active at next reboot\nWARNING: A reboot is required to load this software correctly\nWARNING:     Use the 'request system reboot' command\nWARNING:         when software installation is complete"
```
An unsuccessful rollback would look like this:
```ruby
pp ndev.re.software_rollback!
-> 
"WARNING: Cannot rollback, /packages/junos is not valid"
```

## `reboot!( opts = {} )` <a name="reboot">
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

## `shutdown!( opts = {} )` <a name="shutdown">

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

## `license_install!( opts = {} )` <a name="license_install">
Installs the provided license.  This method will return `true` if the key is installed correctly or a String message indicating the error.

The following options are supported, you **MUST** use either `:key` or `:filename` to provide the license ASCII-text.
```
:key
```
The ASCII-text of the key.
```
:filename
```
The path to the file on the server (not Junos) that contains the ASCII-text of the key.

The following illustates how to load a key from the server filesystem.
```ruby
ndev.re.license_install! :filename=>'/cygwin/home/jschulman/license.txt'
->
true
```
## `license_rm!( license_id )` <a name="license_rm">
Removes either a specific license or `:all` licenses from the target.  This method will return `true` if the action was successful, or a String error-message otherwise.

Removing a specific license:
```ruby
ndev.re.license_rm! "JUNOS410496"
->
true
```
Removing all licenses
```ruby
ndev.re.license_rm! :all
->
true
```

## `licenses( opts = {} )` <a name="licenses">

Returns a Hash structure of information gathered from the "show system license" command.

The following options are supported:
```
:keys => true
```
Returns the license key value in ASCII text format.

Without the `:keys` option:

```ruby
pp ndev.re.licenses
-> 
{"JUNOS410496"=>
  {:state=>"valid",
   :version=>"2",
   :serialnumber=>"91730A00092074",
   :customer=>"LABVSRXJuniper-SEs",
   :features=>
    {"all"=>
      {:description=>"All features",
       :date_start=>"2013-02-05",
       :date_end=>"2014-02-06"}}}}
```
With the `:keys` option:
```ruby
pp ndev.re.licenses :keys=>true
-> 
{"JUNOS410496"=>
  {:state=>"valid",
   :version=>"2",
   :serialnumber=>"91730A00092074",
   :customer=>"LABVSRXJuniper-SEs",
   :features=>
    {"all"=>
      {:description=>"All features",
       :date_start=>"2013-02-05",
       :date_end=>"2014-02-06"}},
   :key=>
    "\nJUNOS410496 aeaqec agaia3 27n65m fq4ojr g4ztaq jqgayd\n            smrqg4 2aye2m ifbfmu DEADBEF k3tjob sxelkt\n  <snip>"}}
```

## `ping( host, opts = {} )` <a name="ping">

Issues a 'ping' from the Junos target, very handy for troubleshooting.  This method will return `true` if the ping action was successful, or `false` otherwise.

The following options are supported, and they are the same as documented by the Junos techpubs:
```
      :do_not_fragment, :inet, :inet6, :strict,      
      :count, :interface, :interval, :mac_address,
      :routing_instance, :size, :source, :tos, :ttl, :wait
```
Here is a ping example that uses the 'do-no-fragment' and 'count' options:
```ruby
ndev.re.ping "192.168.56.1", :count => 5, :do_not_fragment => true
->
true
```
