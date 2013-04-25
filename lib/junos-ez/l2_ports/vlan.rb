class Junos::Ez::L2ports::Provider::VLAN < Junos::Ez::L2ports::Provider  
  
  ### ---------------------------------------------------------------
  ### XML top placement
  ### ---------------------------------------------------------------
  
  def xml_at_top
    Nokogiri::XML::Builder.new {|xml| xml.configuration {
      xml.interfaces {
        return xml_at_element_top( xml, @name )
      }
    }}
  end
  
  # set the edit anchor inside the ethernet-switching stanza
  # we will need to 'up-out' when making changes to the 
  # unit information, like description
  
  def xml_at_element_top( xml, name )
    xml.interface {
      xml.name name
      xml.unit { 
        xml.name '0'
        return xml
      }
    }    
  end
     
  ### ---------------------------------------------------------------
  ### XML property readers
  ### ---------------------------------------------------------------  

  def xml_get_has_xml( xml )              
    # second unit contains the family/ethernet-switching stanza
    got = xml.xpath('//unit')[0]
    
    # if this resource doesn't exist we need to default some 
    # values into has/should variables
    
    unless got
      @has[:vlan_tagging] = false
      @should = @has.clone
    end
    
    got
  end
  
  def xml_read_parser( as_xml, as_hash )    
    set_has_status( as_xml, as_hash )  
    
    xml_when_item(as_xml.xpath('description')){|i| as_hash[:description] = i.text}

    f_eth = as_xml.xpath('family/ethernet-switching')        
    as_hash[:vlan_tagging] = f_eth.xpath('port-mode').text.chomp == 'trunk' 

    # --- access port        
    if as_hash[:vlan_tagging] == false
      xml_when_item(f_eth.xpath('vlan/members')){|i| as_hash[:untagged_vlan] = i.text.chomp }
      return
    end
    
    # --- trunk port    
    xml_when_item(f_eth.xpath('native-vlan-id')){|i| as_hash[:untagged_vlan] = i.text.chomp }
    as_hash[:tagged_vlans] = f_eth.xpath('vlan/members').collect { |v| v.text.chomp }    
  end
    
  ### ---------------------------------------------------------------
  ### XML property writers
  ### ---------------------------------------------------------------    
  
  ## overload the xml_build_change method so we can 'copy-thru'
  ## some of the has -> should values.  this way we don't need
  ## to munge all of the state-transition code.
  
  def xml_build_at_here( xml )
    xml.family {
      xml.send(:'ethernet-switching') {
        return xml
      }
    }
  end
  
  def xml_build_change( xml_at_here = nil )
    @should[:untagged_vlan] ||= @has[:untagged_vlan]    
    super xml_build_at_here( xml_at_top )
  end
     
  ## ----------------------------------------------------------------
  ## :description
  ## ----------------------------------------------------------------
  
  ## overload default method since we need to "up-out" of the
  ## ethernet-switching stanza
  
  def xml_change_description( xml )
    unit = xml.parent.xpath('ancestor::unit')[0]
    Nokogiri::XML::Builder.with( unit ){ |x| 
      xml_set_or_delete( x, 'description', @should[:description] )
    }
  end
  
  ## ----------------------------------------------------------------
  ## :vlan_tagging
  ## ----------------------------------------------------------------
  
  def xml_change_vlan_tagging( xml )    
    port_mode = should_trunk? ? 'trunk' : 'access'
    xml.send(:'port-mode', port_mode )
    
    # when the vlan_tagging value changes then this method
    # will trigger updates to the untagged_vlan and tagged_vlans
    # resource values as well.
    
    upd_untagged_vlan( xml )
    upd_tagged_vlans( xml ) 
    
    return true
  end  
  
  ## ----------------------------------------------------------------
  ## :tagged_vlans
  ## ----------------------------------------------------------------
  
  def xml_change_tagged_vlans( xml )  
    return false if mode_changed?  
    upd_tagged_vlans( xml )
  end
  
  def upd_tagged_vlans( xml )        
    return false unless should_trunk?
    
    v_should = @should[:tagged_vlans] || []
    
    if v_should.empty?
      xml.vlan Netconf::JunosConfig::DELETE
      return true
   end
    
    v_has = @has[:tagged_vlans] || []    
    v_has = v_has.map(&:to_s)    
    v_should = v_should.map(&:to_s)    
    
    del = v_has - v_should
    add = v_should - v_has 
    
    if add or del
      xml.vlan {
        del.each { |v| xml.members v, Netconf::JunosConfig::DELETE }
        add.each { |v| xml.members v }
      }  
    end
    
    return true    
  end    
  
  ## ----------------------------------------------------------------  
  ## :untagged_vlan
  ## ----------------------------------------------------------------  
  
  def xml_change_untagged_vlan( xml )   
    return false if mode_changed?         
    upd_untagged_vlan( xml )
  end  
  
  def upd_untagged_vlan( xml )
    self.class.change_untagged_vlan( self, xml )
  end    
  
end

##### ---------------------------------------------------------------
##### Class methods for handling state-transitions between
##### configurations (tagged/untagged)
##### ---------------------------------------------------------------

class Junos::Ez::L2ports::Provider::VLAN
    
  # creating some class definitions ...
  # this is a bit complicated because we need to handle port-mode
  # change transitions; basically dealing with the fact that
  # trunk ports use 'native-vlan-id' and access ports have a
  # vlan member definition; i.e. they don't use native-vlan-id, ugh.
  # Rather than doing all this logic as if/then/else statements,
  # I've opted to using a proc jump-table technique.  Lessons
  # learned from lots of embedded systems programming :-)    
    
  def self.init_jump_table
    
    # auto-hash table, majik!
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
    
  ### invoke the correct method from the jump table
  ### based on the three criteria to select the action
  
  def self.change_untagged_vlan( this, xml )
    @@ez_l2_jmptbl ||= init_jump_table    
    proc = @@ez_l2_jmptbl[this.is_trunk?][this.should_trunk?][this.should[:untagged_vlan].nil?]
    proc.call( this, xml )
  end
  
  ### -------------------------------------------------------------
  ### The following are all the change transition functions for
  ### each of the use-cases
  ### -------------------------------------------------------------
  
  def self.ac_ac_nountg( this, xml )
    xml.vlan Netconf::JunosConfig::DELETE
  end
  
  def self.ac_tr_nountg( this, xml )      
    unless (untg_vlan = this.has[:tagged_vlans]).nil?
      xml.vlan {
        xml.members untg_vlan, Netconf::JunosConfig::DELETE
      }              
    end
  end
  
  def self.tr_ac_nountg( this, xml )
    xml.send :'native-vlan-id', Netconf::JunosConfig::DELETE              
    xml.vlan( Netconf::JunosConfig::DELETE ) if this.has[:tagged_vlans]
  end
  
  def self.tr_tr_nountg( this, xml )
    xml.send :'native-vlan-id', Netconf::JunosConfig::DELETE              
  end
  
  def self.ac_ac_untg( this, xml )
    xml.vlan( Netconf::JunosConfig::REPLACE ) {
      xml.members this.should[:untagged_vlan]
    }            
  end
  
  def self.ac_tr_untg( this, xml )      
    was_untg_vlan = this.has[:untagged_vlan]
    
    xml.vlan( Netconf::JunosConfig::REPLACE ) { 
      xml.members was_untg_vlan, Netconf::JunosConfig::DELETE if was_untg_vlan
    }
    xml.send :'native-vlan-id', this.should[:untagged_vlan]              
  end
  
  def self.tr_ac_untg( this, xml )
    xml.send :'native-vlan-id', Netconf::JunosConfig::DELETE              
    xml.vlan( Netconf::JunosConfig::REPLACE ) {
      xml.members this.should[:untagged_vlan]
    }            
  end
  
  def self.tr_tr_untg( this, xml )
    xml.send :'native-vlan-id', this.should[:untagged_vlan]              
  end
end

##### ---------------------------------------------------------------
##### Provider collection methods
##### ---------------------------------------------------------------

class Junos::Ez::L2ports::Provider::VLAN
  
  def build_list
    
    begin
      got = @ndev.rpc.get_ethernet_switching_interface_information(:summary=>true)
    rescue => e
      # in this case, no ethernet-switching is enabled so return empty list
      return []
    end
    
    got.xpath('interface/interface-name').collect{ |ifn| ifn.text.split('.')[0] }
  end
  
  def build_catalog
    @catalog = {}    
    return @catalog if list.empty?
    
    @ndev.rpc.get_configuration{ |xml|
      xml.interfaces {
        list.each do |port_name|
          Nokogiri::XML::Builder.with( xml.parent ) do |x1|
            x1.interface { x1.name port_name
              x1.unit { x1.name '0' }
            }
          end        
        end
      }      
    }.xpath('interfaces/interface').each do |ifs|
      ifs_name = ifs.xpath('name').text
      unit = ifs.xpath('unit')[0]
      @catalog[ifs_name] = {}
      xml_read_parser( unit, @catalog[ifs_name] )
    end
    @catalog
  end
  
end