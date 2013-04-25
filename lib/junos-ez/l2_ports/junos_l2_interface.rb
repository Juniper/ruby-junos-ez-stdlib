=begin
* Puppet Module  : Provder: netdev
* Author         : Jeremy Schulman
* File           : junos_l2_interface.rb
* Version        : 2012-11-07
* Platform       : EX | QFX | SRX
* Description    : 
*
*   This file contains the Junos specific code to control basic
*   Layer 2 interface configuration on platforms that support 
*   the [edit vlans] hierarchy.  L2 interfaces are assumed
*   to be at [edit interface <name> unit 0 family ethernet-switching]
*
* Copyright (c) 2012  Juniper Networks. All Rights Reserved.
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

class Puppet::Provider::Junos::L2Interface < Puppet::Provider::Junos 

  ### ---------------------------------------------------------------  
  ### triggered from Provider #exists?
  ### ---------------------------------------------------------------  
  
  def netdev_res_exists?
    
    self.class.init_class_vars    
        
    return false unless (ifl_config = init_resource)
    
    @ndev_res[:description] = ifl_config.xpath('description').text.chomp    
    fam_eth_cfg = ifl_config.xpath('family/ethernet-switching')      
    
    return false if fam_eth_cfg.empty?
    
    netdev_retrieve_fam_eth_info( fam_eth_cfg )
    
    return true
  end   
  
  ### ---------------------------------------------------------------
  ### called from #netdev_exists?
  ### ---------------------------------------------------------------  
  
  def init_resource
    
    @ndev_res ||= NetdevJunos::Resource.new( self, "interfaces" )
    
    @ndev_res[:description] = ''
    @ndev_res[:vlan_tagging] = :disable
    @ndev_res[:untagged_vlan] = ''
    @ndev_res[:tagged_vlans] = []        
    
    resource[:description] ||= default_description
    resource[:tagged_vlans] = resource[:tagged_vlans].to_a || []     
    resource[:untagged_vlan] ||= ''     # if not set in manifest, it is nil   
    resource[:vlan_tagging] = :enable unless resource[:tagged_vlans].empty?    
    
    ndev_config = @ndev_res.getconfig
    
    return false unless (ifl_config = ndev_config.xpath('//interface/unit')[0])
    
    @ndev_res.set_active_state( ifl_config )  
    
    return ifl_config
  end
  
  def default_description
    "Puppet created netdev_l2_interface: #{resource[:name]}"
  end
  
  def netdev_retrieve_fam_eth_info( fam_eth_cfg )
    
    @ndev_res[:vlan_tagging] = fam_eth_cfg.xpath('port-mode').text.chomp == 'trunk' ? :enable : :disable
    
    # --- access port      
    
    if @ndev_res[:vlan_tagging] == :disable
      @ndev_res[:untagged_vlan] = fam_eth_cfg.xpath('vlan/members').text.chomp || ''
      return
    end
    
    # --- trunk port
    
    @ndev_res[:untagged_vlan] = fam_eth_cfg.xpath('native-vlan-id').text.chomp
    @ndev_res[:tagged_vlans] = fam_eth_cfg.xpath('vlan/members').collect { |v| v.text.chomp }    
  end
  
  def is_trunk?
    @ndev_res[:vlan_tagging] == :enable
  end
  
  def should_trunk?
    resource[:vlan_tagging] == :enable
  end
  
  def mode_changed?
    @ndev_res[:name].nil? or (resource[:vlan_tagging] != @ndev_res[:vlan_tagging])
  end
  
  ##### ------------------------------------------------------------
  #####              XML Resource Building
  ##### ------------------------------------------------------------   
  
  # override default 'top' method to create the unit sub-interface
  
  def netdev_resxml_top( xml ) 
    xml.interface {
      xml.name resource[:name]  
      xml.unit { 
        xml.name '0'  
        return xml
      }
    }
  end
  
  # override default 'edit' method to place 'dot' inside
  # the family ethernet-switching stanza
  
  def netdev_resxml_edit( xml )
    xml.family { 
      xml.send(:'ethernet-switching') {
        return xml
      }
    }
  end
  
  ###
  ### :description
  ###
  
  def xml_change_description( xml )
    par = xml.instance_variable_get(:@parent)    
    
    Nokogiri::XML::Builder.with(par.at_xpath('ancestor::unit')) {
      |dot|        
      dot.description resource[:description]
    }
  end
  
  ####
  #### :vlan_tagging
  ####
  
  def xml_change_vlan_tagging( xml )
    
    port_mode = should_trunk? ? 'trunk' : 'access'
    xml.send(:'port-mode', port_mode )
    
    # when the vlan_tagging value changes then this method
    # will trigger updates to the untagged_vlan and tagged_vlans
    # resource values as well.
    
    upd_untagged_vlan( xml )
    upd_tagged_vlans( xml )
    
  end
  
  ### ---------------------------------------------------------------
  ### XML:tagged_vlans
  ### ---------------------------------------------------------------  
  
  def xml_change_tagged_vlans( xml )  
    return if mode_changed?  
    upd_tagged_vlans( xml )
  end
  
  def upd_tagged_vlans( xml )
        
    return unless should_trunk?
    
    should = resource[:tagged_vlans] || []
    
    if should.empty?
      xml.vlan Netconf::JunosConfig::DELETE
      return
   end
    
    has = @ndev_res[:tagged_vlans] || []    
    has = has.map(&:to_s)    
    should = should.map(&:to_s)    
    
    del = has - should
    add = should - has 
    
    if add or del
      Puppet.debug "#{resource[:name]}: Adding VLANS: [#{add.join(',')}]" unless add.empty?
      Puppet.debug "#{resource[:name]}: Deleting VLANS: [#{del.join(',')}]" unless del.empty?      
      xml.vlan {
        del.each { |v| xml.members v, Netconf::JunosConfig::DELETE }
        add.each { |v| xml.members v }
      }  
    end
  end  
  
  ### ---------------------------------------------------------------
  ### XML:untagged_vlan
  ### ---------------------------------------------------------------  
  
  def xml_change_untagged_vlan( xml )           
    return if mode_changed?         
    upd_untagged_vlan( xml )
  end  
  
  def upd_untagged_vlan( xml )
    self.class.change_untagged_vlan( self, xml )
  end  
  
  class << self
    
    # creating some class definitions ...
    # this is a bit complicated because we need to handle port-mode
    # change transitions; basically dealing with the fact that
    # trunk ports use 'native-vlan-id' and access ports have a
    # vlan member definition; i.e. they don't use native-vlan-id, ugh.
    # Rather than doing all this logic as if/then/else statements,
    # I've opted to using a proc jump-table technique.  Lessons
    # learned from lots of embedded systems programming :-)    
    
    def initcvar_jmptbl_untagged_vlan
      
      # auto-hash table
      hash = Hash.new(&(p=lambda{|h,k| h[k] = Hash.new(&p)}))
      
      # ------------------------------------------------------------------
      # -   jump table for handling various untagged vlan change use-cases      
      # ------------------------------------------------------------------      
      # There are three criteria for selection:  
      # | is_trunk | will_trunk | no_untg |
      # ------------------------------------------------------------------
      # - will not have untagged vlan 
      hash[false][false][true] = self.method(:ac_ac_nountg)
      hash[false][true][true] = self.method(:ac_tr_nountg)
      hash[true][false][true] = self.method(:tr_ac_nountg)
      hash[true][true][true] = self.method(:tr_tr_nountg)
      # - will have untagged vlan 
      hash[false][false][false] = self.method(:ac_ac_untg)
      hash[false][true][false] = self.method(:ac_tr_untg)
      hash[true][false][false] = self.method(:tr_ac_untg)
      hash[true][true][false] = self.method(:tr_tr_untg)
      
      hash
    end
    
    ### initialize the jump table once as a class variable
    ### this is called from #init_resource
    
    def init_class_vars                      
      @@untgv_jmptbl ||= initcvar_jmptbl_untagged_vlan      
    end
    
    ### invoke the correct method from the jump table
    ### based on the three criteria to select the action
    
    def change_untagged_vlan( this, xml )
      proc = @@untgv_jmptbl[this.is_trunk?][this.should_trunk?][this.resource[:untagged_vlan].empty?]
      proc.call( this, xml )
    end
    
    ### -------------------------------------------------------------
    ### The following are all the change transition functions for
    ### each of the use-cases
    ### -------------------------------------------------------------
    
    def ac_ac_nountg( this, xml )
      xml.vlan Netconf::JunosConfig::DELETE
    end
    
    def ac_tr_nountg( this, xml )      
      unless (untg_vlan = this.ndev_res[:tagged_vlans]).empty?
        xml.vlan {
          xml.members untg_vlan, Netconf::JunosConfig::DELETE
        }              
      end
    end
    
    def tr_ac_nountg( this, xml )
      xml.send :'native-vlan-id', Netconf::JunosConfig::DELETE              
      xml.vlan( Netconf::JunosConfig::DELETE ) if this.ndev_res[:tagged_vlans]
    end
    
    def tr_tr_nountg( this, xml )
      xml.send :'native-vlan-id', Netconf::JunosConfig::DELETE              
    end
    
    def ac_ac_untg( this, xml )
      xml.vlan( Netconf::JunosConfig::REPLACE ) {
        xml.members this.resource[:untagged_vlan]
      }            
    end
    
    def ac_tr_untg( this, xml )      
      was_untg_vlan = this.ndev_res[:untagged_vlan]
      
      xml.vlan( Netconf::JunosConfig::REPLACE ) { 
        xml.members was_untg_vlan, Netconf::JunosConfig::DELETE if was_untg_vlan
      }
      xml.send :'native-vlan-id', this.resource[:untagged_vlan]              
    end
    
    def tr_ac_untg( this, xml )
      xml.send :'native-vlan-id', Netconf::JunosConfig::DELETE              
      xml.vlan( Netconf::JunosConfig::REPLACE ) {
        xml.members this.resource[:untagged_vlan]
      }            
    end
    
    def tr_tr_untg( this, xml )
      xml.send :'native-vlan-id', this.resource[:untagged_vlan]              
    end
            
  end # class methods for changing untagged_vlan
end


