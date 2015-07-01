class Junos::Ez::L2ports::Provider::BRIDGE_DOMAIN< Junos::Ez::L2ports::Provider  
  
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
      xml.send(:'native-vlan-id')
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
    ## reading is anchored at the [... unit 0 ...] level
    set_has_status( as_xml, as_hash )  
    
    xml_when_item(as_xml.xpath('description')){|i| as_hash[:description] = i.text}

    f_eth = as_xml.xpath('family/bridge')        
    as_hash[:vlan_tagging] = f_eth.xpath('interface-mode').text.chomp == 'trunk' 
    
    # obtain a copy of the running state, this is needed in case the config
    # is located under the [edit vlans] stanza vs. [edit interfaces]
    
    ifs_name = @name || as_xml.xpath('ancestor::interface/name').text.strip
    eth_port_vlans = _get_eth_port_vlans_h( ifs_name )
    @under_vlans = []
    
    # --- access port        
    
    if as_hash[:vlan_tagging] == false
      xml_when_item(f_eth.xpath('domain/vlan-id')){ |i| as_hash[:untagged_vlan] = i.text.chomp }
      unless as_hash[:untagged_vlan]
        as_hash[:untagged_vlan] = eth_port_vlans[:untagged]
        @under_vlans << eth_port_vlans[:untagged]
      end
      return
    end
    
    # --- trunk port    
    
    as_hash[:untagged_vlan] ||= eth_port_vlans[:untagged]    
    as_hash[:tagged_vlans] = f_eth.xpath('domain/vlan-id-list').collect { |v| v.text.chomp }.to_set   
    (eth_port_vlans[:tagged] - as_hash[:tagged_vlans]).each do |vlan|
      as_hash[:tagged_vlans] << vlan
      @under_vlans << vlan
    end
    
    # native-vlan-id is set at the interface level, and is the VLAN-ID, not the vlan
    # name.  So we need to do a bit of translating here.  The *ASSUMPTION* is that the
    # native-vlan-id value is a given VLAN in the tagged_vlan list.  So we will use 
    # that list to do the reverse lookup on the tag-id => name
    
    xml_when_item(f_eth.xpath('ancestor::interface/native-vlan-id')){ |i| 
      as_hash[:untagged_vlan] = _vlan_tag_id_to_name( i.text.chomp, as_hash ) 
    }
  end
    
  ### ---------------------------------------------------------------
  ### XML on_create, on_delete handlers
  ### ---------------------------------------------------------------   
  
  ## overload the xml_on_delete method since we may need
  ## to do some cleanup work in the [edit vlans] stanza
  
  def xml_on_delete( xml )
    @ifd = xml.instance_variable_get(:@parent).at_xpath('ancestor::interface')
    @ifd.xpath('//native-vlan-id').remove      ## remove the element from the get-config    
    ## need to add check if any native-vlan-id is present or not (untagged vlan)#####
   if is_trunk? and @ifd.xpath('//native-vlan-id')
      _delete_native_vlan_id( xml )
   end
      
    return unless @under_vlans
    return if @under_vlans.empty?

    _xml_rm_under_vlans( xml, @under_vlans )
  end   

  ### ---------------------------------------------------------------
  ### XML property writers
  ### ---------------------------------------------------------------    
  
  def xml_at_here( xml )
    @ifd = xml.instance_variable_get(:@parent).at_xpath('ancestor::interface')
    @ifd.xpath('//native-vlan-id').remove      ## remove the element from the get-config
    xml.family {
      xml.send(:'bridge') {
        return xml
      }
    }
  end
  
  def xml_build_change( nop = nil )
    @under_vlans ||= []       # handles case for create'd port
    
    if mode_changed?
      @should[:untagged_vlan] ||= @has[:untagged_vlan]    
    end
    
    super xml_at_here( xml_at_top )
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
    xml.send(:'interface-mode', port_mode )
    
   # if is_trunk? and not should_trunk?
   #   # trunk --> access
   #   set_ifd_trunking( xml, false )
   # elsif should_trunk? and not is_trunk?
      # access --> trunk
   #   set_ifd_trunking( xml, true )
   # end    
    
    # when the vlan_tagging value changes then this method
    # will trigger updates to the untagged_vlan and tagged_vlans
    # resource values as well.
    # !!! DO NOT SWAP THIS ORDER untagged processing *MUST* BE FIRST!
    
    upd_untagged_vlan( xml )
    upd_tagged_vlans( xml ) 
        
    return true
  end  
  
  def set_ifd_trunking( xml, should_trunk )
   par = xml.instance_variable_get(:@parent)     
   Nokogiri::XML::Builder.with( par.at_xpath( 'ancestor::interface' )) do |dot|
     if should_trunk
       dot.send( :'flexible-vlan-tagging' )
       dot.send( :'encapsulation', 'flexible-ethernet-services' )
     else
       dot.send( :'flexible-vlan-tagging', Netconf::JunosConfig::DELETE )
       dot.send( :'encapsulation', Netconf::JunosConfig::DELETE )
     end
   end       
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
      _xml_rm_under_vlans( xml, del_under_vlans )
      @under_vlans = []
    end
    
    if add or del
      #xml.send(:'vlan-id') {
      #  del.each { |v| xml.members v, Netconf::JunosConfig::DELETE }
      #  add.each { |v| xml.members v }
      add.each {|v| print "\n %%%%%%%%%%%%%%%%%% _vlan_name_to_tag_id( v ) \n", _vlan_name_to_tag_id( v )}
      del.each{|v| xml.send(:'vlan-id-list', _vlan_name_to_tag_id( v ), Netconf::JunosConfig::DELETE)}
      add.each{|v| xml.send( :'vlan-id-list', _vlan_name_to_tag_id(v) )}
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

class Junos::Ez::L2ports::Provider::BRIDGE_DOMAIN
    
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
   #^^^^^^^ create log 
     #NetdevJunos::Log.debug "ac_ac_nountg"
     # @@@ a port *MUST* be assigned to a vlan in access mode on MX.
     # @@@ generate an error!
     raise Junos::Ez::NoProviderError, "a port *MUST* be assigned to a vlan in access mode on MX."
     #raise "ERROR!!! a port *MUST* be assigned to a vlan in access mode on MX."     
  end
  
  ########## need to see#################
  def self.ac_tr_nountg( this, xml ) 
    #unless (untg_vlan = this.has[:untagged_vlan]).nil?
    #  this._xml_rm_ac_untagged_vlan( xml )
    #end
    #no action needed handled already
  end
  #########################################
  
  def self.tr_ac_nountg( this, xml )
    #this._delete_native_vlan_id( xml )
    #this._xml_rm_these_vlans( xml, this.has[:tagged_vlans ] ) if this.has[:tagged_vlans] 
    raise Junos::Ez::NoProviderError, "port must be assigned to vlan in access mode on MX"
    #raise "ERROR!! untagged_vlan missing, port must be assigned to a VLAN"   
  end
  
  def self.tr_tr_nountg( this, xml )
    this._delete_native_vlan_id( xml )  
  end
  
  ## ----------------------------------------------------------------
  ## transition where port WILL-HAVE untagged-vlan
  ## ----------------------------------------------------------------
  
  def self.ac_ac_untg( this, xml )
    #this._xml_rm_ac_untagged_vlan( xml )
    vlan_id = this._vlan_name_to_tag_id( this.should[:untagged_vlan] )
    xml.send :'vlan-id', vlan_id 
  end
      
  def self.ac_tr_untg( this, xml )    
    was_untg_vlan = this.has[:untagged_vlan]
    this._set_native_vlan_id( xml, this.should[:untagged_vlan] )
    this._xml_rm_ac_untagged_vlan( xml ) if was_untg_vlan   
  end   
   
  def self.tr_ac_untg( this, xml ) 
    this._delete_native_vlan_id( xml )
    #this._xml_rm_these_vlans( xml, this.has[:tagged_vlans ] ) if this.has[:tagged_vlans]         
    vlan_id = this._vlan_name_to_tag_id( this.should[:untagged_vlan] )
    xml.send( :'vlan-id', vlan_id )
    print "xml: ", xml.to_xml
  end
  
  def self.tr_tr_untg( this, xml )
    this._set_native_vlan_id(xml, this.should[:untagged_vlan])
  end
 
end

##### ---------------------------------------------------------------
##### Provider collection methods
##### ---------------------------------------------------------------

class Junos::Ez::L2ports::Provider::BRIDGE_DOMAIN
  
  def build_list
    begin
      got = @ndev.rpc.get_bridge_instance_information( :brief => true)
    rescue => e
      # in this case, no ethernet-switching is enabled so return empty list
      return []
    end   
    got.xpath('//l2iff-interface-name').collect{ |ifn| ifn.text.split('.')[0] }
  end
  
  def build_catalog
    @catalog = {}    
    return @catalog if list!.empty?
    list.each do |ifs_name|
      @ndev.rpc.get_configuration{ |xml|
        xml.interfaces {
          xml_at_element_top( xml, ifs_name )
        }
      }.xpath('interfaces/interface').each do |ifs_xml|
        @catalog[ifs_name] = {}
        unit = xml_get_has_xml( ifs_xml )
        xml_read_parser( unit, @catalog[ifs_name] )
      end
    end    
    
    @catalog
  end
  
end

##### ---------------------------------------------------------------
#####               !!!!! PRIVATE METHODS !!!!
##### ---------------------------------------------------------------

class Junos::Ez::L2ports::Provider::BRIDGE_DOMAIN
  private
  
  def _get_eth_port_vlans_h( ifs_name )
    got = @ndev.rpc.get_bridge_instance_information(:interface => ifs_name)
    ret_h = {:untagged => nil, :tagged => Set.new }
    got.xpath('//l2ng-l2ald-iff-interface-entry').each do |vlan|
      # one of the node-set elements (the first one?) contains the interface name.
      # this doesn't have any VLAN information, so skip it.
      next if vlan.xpath('l2iff-interface-name')
      
      vlan_name = vlan.xpath('//l2rtb-bridge-vlan').text.strip 
      if vlan.xpath('//l2rtb-interface-vlan-member-tagness')
        tgdy = vlan.xpath('//l2rtb-interface-vlan-member-tagness').text.strip
        if tgdy == 'untagged'
          ret_h[:untagged] = vlan_name
        else
          ret_h[:tagged] << vlan_name
        end      
      else
        ret_h[:tagged]<<vlan_name       
      end         
    end
    ret_h
  end
end

### ---------------------------------------------------------------
### [edit vlans] - for interfaces configured here ...
### ---------------------------------------------------------------

class Junos::Ez::L2ports::Provider::BRIDGE_DOMAIN
  
    def _xml_edit_under_vlans( xml ) 
    Nokogiri::XML::Builder.with( xml.doc.root ) do |dot|
      dot.send(:'vlan-id'){
        return dot
      }
    end      
  end
  
  def _xml_rm_under_vlans( xml, vlans )
    if vlans.any?
      at_vlans = _xml_edit_under_vlans( xml )
      vlans.each do |vlan_id|
        Nokogiri::XML::Builder.with( at_vlans.parent ) do |this|
          this.domain {
            this.vlan_id vlan_id
            this.interface( Netconf::JunosConfig::DELETE ) { this.name @name }
          }
        end
      end
    end    
  end
  
  def _xml_rm_ac_untagged_vlan( xml )
    if @under_vlans.empty?
      xml.send :'vlan-id', Netconf::JunosConfig::DELETE    
    else
      _xml_rm_under_vlans( xml, [ @has[:untagged_vlan ] ] )
      @under_vlans = []    
    end
  end
  
  def _xml_rm_these_vlans( xml, vlans )
    if @under_vlans.empty?
      xml.send :'vlan-id', ( Netconf::JunosConfig::DELETE ) 
    else
      # could be a mix between [edit vlans] and [edit interfaces] ...
      v_has = vlans.to_set
      del_under_vlans = v_has & @under_vlans
      _xml_rm_under_vlans( xml, del_under_vlans )
      if v_has ^ @under_vlans
        xml.send :'vlan-id', ( Netconf::JunosConfig::DELETE ) 
      end
      @under_vlans = []        
    end
  end
  
end


class Junos::Ez::L2ports::Provider::BRIDGE_DOMAIN
    
  def _vlan_name_to_tag_id( vlan_name )
    tag_id = @ndev.rpc.get_configuration { |xml|
      xml.send(:'bridge-domains') { xml.domain { xml.name vlan_name }}
    }.xpath('//vlan-id').text.chomp
    
    raise ArgumentError, "VLAN '#{vlan_name}' not found" if tag_id.empty?
    return tag_id
  end
  
  def _vlan_tag_id_to_name( tag_id, my_hash )
    # get the candidate configuration for each VLAN named in tagged_vlans and
    # then map it to the corresponding vlan-id.  this is not very effecient, but
    # at present there is no other way without getting into a cache mech.   
    vlan_name = @ndev.rpc.get_configuration { |xml|
      xml.send(:'bridge-domains') {
        my_hash[:tagged_vlans].each do |v_name|
          xml.domain { 
            xml.name v_name 
            xml.send(:'vlan-id')
          }
        end
      }
    }.xpath("//domain[vlan-id = '#{tag_id}']/name").text.chomp    
    
    raise ArgumentError, "VLAN-ID '#{tag_id}' not found" if vlan_name.empty?
    return vlan_name
  end
  
end

class Junos::Ez::L2ports::Provider::BRIDGE_DOMAIN
  def _at_native_vlan_id( xml )
    ifd
  end
  
  def _delete_native_vlan_id( xml )
    Nokogiri::XML::Builder.with( @ifd ) do |dot|
      dot.send :'native-vlan-id', Netconf::JunosConfig::DELETE
    end
    return true
  end
  
  def _set_native_vlan_id( xml, vlan_name )
    Nokogiri::XML::Builder.with( @ifd ) do |dot|
      dot.send :'native-vlan-id', _vlan_name_to_tag_id( vlan_name )
      xml.send( :'vlan-id-list', _vlan_name_to_tag_id( vlan_name) )
    end    
    return true
  end
  
 
end
