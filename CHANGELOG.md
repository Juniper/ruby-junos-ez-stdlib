# 2013-April

  0.0.10: 2013-04-26
  
    Initial release of code into RubyGems.  Code tested on EX and SRX-branch. Consider this code
    as "early-adopter".  Comments/feedback is welcome and appreciated.

  0.0.11: 2013-04-26
  
    Updated Junos::Ez::RE::Utils
      #memory changed :procs from Hash to Array  
      #users changed return from Hash to Array
    
  0.0.12: 2013-04-26
  
    Updated Junos::Ez::FS:Utils#ls to include :symlink information
    Adding Junos::Ez::Users::Provider for login management
    Adding Junos::Ez::UserAuths::Provider for SSH-key management
    
  0.0.14: 2013-04-28
  
    Completed initial documentation.  Still more work to be done with these files
    but the "enough to get started" information is now available
    
# 2013-May    

  0.0.15: 2013-05-02
  
    L2ports - added support for framework to read [edit vlans] stanza to recognize interfaces configured
    there vs. under [edit interfaces]
    
    IPports - added :acl_in and :acl_out for stateless ACL filtering.  added .status method to return
    runtime status information about the port
    
    RE::Utils - misc updates, and documentation

  0.0.16: 2013-05-03
  
    RE::Utils - added support for license-key management.  Renamed "software" methods from "xxx_software"
    to "software_xxx" to be consistent with other naming usage.  Updated docs.
  
  0.0.17: 2013-05-05
  
    FS::Utils - updated docs.  fixed methods so that all "error" scenarios raise IOError excaptions.
  
  0.1.0: 2013-05-06
  
    All docs and code _finished_ for the inital release of code.  Always more to do, but at this
    point, declaring the framework "good for early adopter testing".  Looking forward to bug-reports,
    please open issues against this repo.  Thank you!
    
  0.1.1: 2013-05-29
  
    Fixed a small bug in fact gathering for hardwaremodel
  
# 2013-July

  0.1.2: 2013-07-04
  
    Fixed issue#3.  Previously this gem would not work with non-VC capable EX switches.  Updated
    the `facts/version.rb` file to handle these devices.  Also added a new fact `:vc_capable` that
    is set to `true` if the EX can support virtual-chassis, and `false` if it cannot.

# 2013-Aug

  0.2.0: 
  
    Fixed issue #6.  Added support for EX4300 platform.  Added new provider for Link Aggregation Group
    resources (LAGports)

# 2016-March

  1.0.0:

    Fixed issues
      Issue #17 Add support for OCX device.
      Issue #20 "under development" error is thrown while importing the interface_create recipe from the Chef-Server.
      Issue #22 "netdev_vlan" resource action delete is not working fine while invoking from the JUNOS Chef-Client.
      Issue #23 RPC command error: commit-configuration is getting thrown on Invoking the "netdev_lag" resource from
                 JUNOS Chef Client.
      Issue #27 Duplicate declaration of lag configuration in a recipe is giving NoMethodError: undefined method
                 `properties' for nil:NilClass.
      Issue #30 Error in rerunning netdev_lag interface.
      Issue #33 undefined method `properties' for nil:NilClass error is thrown if the backup RE is unreachable.
      Issue #35 Error in running chef client from Backup RE.
      Issue #39 Getting 'Junos::Ez::NoProviderError' error on qfx device.
      Issue #42 Raise exception to handle warnings in <error-severity>.

    Enhancement
      * Add support for configuring l2_interface on MX device.
      * Add support for provider 'group' for configuring JUNOS groups.
