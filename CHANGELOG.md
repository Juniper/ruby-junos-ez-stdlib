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

  0.0.15: 2013-05-02
  
    L2ports - added support for framework to read [edit vlans] stanza to recognize interfaces configured
    there vs. under [edit interfaces]
    
    IPports - added :acl_in and :acl_out for stateless ACL filtering.  added .status method to return
    runtime status information about the port
    
    RE::Utils - misc updates, and documentation
