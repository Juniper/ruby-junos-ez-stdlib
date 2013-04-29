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
    
    # obtain a copy of the running state, this is needed in case the config
    # is located under the [edit vlans] stanza vs. [edit interfaces]
    
    ifs_name = @name || as_xml.xpath('ancestor::interface/name').text.strip
    eth_port_vlans = _get_eth_port_vlans_h( ifs_name )
    @under_vlans = []
    
    # --- access port        
    
    if as_hash[:vlan_tagging] == false
      xml_when_item(f_eth.xpath('vlan/members')){ |i| as_hash[:untagged_vlan] = i.text.chomp }
      unless as_hash[:untagged_vlan]
        as_hash[:untagged_vlan] = eth_port_vlans[:untagged]
        @under_vlans << eth_port_vlans[:untagged]
      end
      return
    end
    
    # --- trunk port    
    
    xml_when_item(f_eth.xpath('native-vlan-id')){|i| as_hash[:untagged_vlan] = i.text.chomp }
    as_hash[:untagged_vlan] ||= eth_port_vlans[:untagged]    
    as_hash[:tagged_vlans] = f_eth.xpath('vlan/members').collect { |v| v.text.chomp }.to_set   
    (eth_port_vlans[:tagged] - as_hash[:tagged_vlans]).each do |vlan|
      as_hash[:tagged_vlans] << vlan
      @under_vlans << vlan
    end
    
  end
    
  ### ---------------------------------------------------------------
  ### XML on_create, on_delete handlers
  ### ---------------------------------------------------------------   
  
  ## overload the xml_on_delete method since we may need
  ## to do some cleanup work in the [edit vlans] stanza
  
  def xml_on_delete( xml )
    return unless @under_vlans
    return if @under_vlans.empty?
    _xml_del_under_vlans( xml, @under_vlans )
  end   
  
  def _xml_del_under_vlans( xml, vlans )
    Nokogiri::XML::Builder.with( xml.doc.root ) do |dot|
      dot.vlans {
        x_vlans = dot
        vlans.each do |vlan|
          Nokogiri::XML::Builder.with( x_vlans.parent ) do |xv|
            xv.vlan {
              xv.name vlan 
              xv.interface(Netconf::JunosConfig::DELETE) { xv.name @name }
            }
          end
        end      
      }
    end    
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
    
    @should[:tagged_vlans] = @should[:tagged_vlans].to_set if @should[:tagged_vlans].kind_of? Array
    @has[:tagged_vlans] = @has[:tagged_vlans].to_set if @has[:tagged_vlans].kind_of? Array    

    v_should = @should[:tagged_vlans] || Set.new    
    v_has = @has[:tagged_vlans] || Set.new    
    
    del = v_has - v_should
    add = v_should - v_has 

    del_under_vlans = del & @under_vlans    

    unless del_under_vlans.empty?
      del = del ^ @under_vlans
      _xml_del_under_vlans( xml, del_under_vlans )
      @under_vlans = []
    end

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
    return @catalog if list!.empty?
    
    list.each do |ifs_name|
      @ndev.rpc.get_configuration{ |xml|
        xml.interfaces {
          xml.interface {
            xml.name ifs_name
            xml.unit { xml.name '0' }
          }
        }
      }.xpath('interfaces/interface').each do |ifs_xml|
        @catalog[ifs_name] = {}
        unit = ifs_xml.xpath('unit')[0]        
        xml_read_parser( unit, @catalog[ifs_name] )
      end
    end    
    
    @catalog
  end
  
end

##### ---------------------------------------------------------------
#####               !!!!! PRIVATE METHODS !!!!
##### ---------------------------------------------------------------

class Junos::Ez::L2ports::Provider::VLAN
  private
  
  def _get_eth_port_vlans_h( ifs_name )
    
    got = @ndev.rpc.get_ethernet_switching_interface_information(:interface_name => ifs_name)
    ret_h = {:untagged => nil, :tagged => Set.new }
    got.xpath('//interface-vlan-member').each do |vlan|
      vlan_name = vlan.xpath('interface-vlan-name').text.strip      
      tgdy = vlan.xpath('interface-vlan-member-tagness').text.strip
      if tgdy == 'untagged'
        ret_h[:untagged] = vlan_name
      else
        ret_h[:tagged] << vlan_name
      end
    end
    ret_h
  end
  
end

##### ---------------------------------------------------------------
##### Resource Methods
##### ---------------------------------------------------------------

class Junos::Ez::L2ports::Provider::VLAN
  # none.
end
