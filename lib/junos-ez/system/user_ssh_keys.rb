=begin
* Puppet Module  : junos-stdlib
* Author         : Jeremy Schulman
* File           : junos_user.rb
* Version        : 2013-03-20
* Platform       : All
* Description    : 
*
*
* Copyright (c) 2013  Juniper Networks. All Rights Reserved.
*
* YOU MUST ACCEPT THE TERMS OF THIS DISCLAIMER TO USE THIS SOFTWARE, 
* IN ADDITION TO ANY OTHER LICENSES AND TERMS REQUIRED BY JUNIPER NETWORKS.
* 
* JUNIPER IS WILLING TO MAKE THE INCLUDED SCRIPTING SOFTWARE AVAILABLE TO YOU
* ONLY UPON THE CONDITION THAT YOU ACCEPT ALL OF THE TERMS CONTAINED IN THIS
* DISCLAIMER. PLEASE READ THE TERMS AND CONDITIONS OF THIS DISCLAIMER
* CAREFULLY.
*
* THE SOFTWARE CONTAINED IN THIS FILE IS PROVIDED "AS IS." JUNIPER MAKES NO
* WARRANTIES OF ANY KIND WHATSOEVER WITH RESPECT TO SOFTWARE. ALL EXPRESS OR
* IMPLIED CONDITIONS, REPRESENTATIONS AND WARRANTIES, INCLUDING ANY WARRANTY
* OF NON-INFRINGEMENT OR WARRANTY OF MERCHANTABILITY OR FITNESS FOR A
* PARTICULAR PURPOSE, ARE HEREBY DISCLAIMED AND EXCLUDED TO THE EXTENT
* ALLOWED BY APPLICABLE LAW.
*
* IN NO EVENT WILL JUNIPER BE LIABLE FOR ANY DIRECT OR INDIRECT DAMAGES, 
* INCLUDING BUT NOT LIMITED TO LOST REVENUE, PROFIT OR DATA, OR
* FOR DIRECT, SPECIAL, INDIRECT, CONSEQUENTIAL, INCIDENTAL OR PUNITIVE DAMAGES
* HOWEVER CAUSED AND REGARDLESS OF THE THEORY OF LIABILITY ARISING OUT OF THE 
* USE OF OR INABILITY TO USE THE SOFTWARE, EVEN IF JUNIPER HAS BEEN ADVISED OF 
* THE POSSIBILITY OF SUCH DAMAGES.
=end

require 'puppet/provider/junos/junos_parent'

class Puppet::Provider::Junos::SSH_auth_key < Puppet::Provider::Junos
  
  ### --------------------------------------------------------------------
  ### triggered by provider #exists? 
  ### --------------------------------------------------------------------  
  
  def netdev_res_exists?     
    
    # cannot manage the 'active' parameter from the puppet manifest since the
    # type definition is compiled on the server, and doesn't include this :-(
    # so fake it here, set to true always.  this way if someone deactivated
    # it apriori, then this puppet-run will make it active again.

    return false unless (auth = get_junos_config)

    got_key = auth.text.strip
    got_key_skip = got_key.index(' ') + 1
    got_key = got_key[ got_key_skip .. -1 ]
    
    @ndev_res[:key] = got_key
    @ndev_res[:user] = resource[:user]
    @ndev_res[:type] = resource[:type]
    @ndev_res[:target] = resource[:target]
    @ndev_res[:options] = resource[:options]
    
    return true    
  end   
  
  ### ---------------------------------  
  ### ---> override parent method <----
  ### ---------------------------------
  
  def netdev_resxml_top( xml )
    xml.user {
      xml.name resource[:user]
      xml.authentication {
        xml.send(:'ssh-rsa') {
          xml.name 'ssh-rsa ' + resource[:key]
          return xml
        }
      }
    }    
  end  
  
  def get_junos_config
    
    @ndev_res ||= NetdevJunos::Resource.new( self, 'system/login', 'user' )   
    @ndev_res[:unmanaged_active] = true
    
    return nil unless (ndev_config = @ndev_res.getconfig)    
    return nil unless auth_config = ndev_config.xpath("//user/authentication/ssh-rsa")[0]                  
    @ndev_res.set_active_state( auth_config )        
    
    return auth_config        
  end
  
  
  ##### ------------------------------------------------------------
  ##### XML builder routines, one for each property
  ##### ------------------------------------------------------------   
  
  def xml_change_type( xml ) 
  end

  def xml_change_key( xml )
  end

  def xml_change_user( xml )
  end

  def xml_change_target( xml ) 
  end

  def xml_change_options( xml )
  end

end
