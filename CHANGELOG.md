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
