class Junos::Ez::Vlans::Provider::VLAN < Junos::Ez::Vlans::Provider
  
  ### ---------------------------------------------------------------
  ### XML top placement
  ### ---------------------------------------------------------------
  
  def xml_at_top
    Nokogiri::XML::Builder.new{|x| x.configuration{ 
      x.vlans { x.vlan { x.name @name
        return x
      }}
    }}
  end

  ### ---------------------------------------------------------------
  ### XML readers
  ### ---------------------------------------------------------------

  def xml_get_has_xml( xml )
    xml.xpath('//vlan')[0]    
  end
        
  def xml_read_parser( as_xml, as_hash )
    set_has_status( as_xml, as_hash )    
    as_hash[:vlan_id] = as_xml.xpath('vlan-id').text.to_i
    xml_when_item(as_xml.xpath('description')){ |i| as_hash[:description] = i.text }
    xml_when_item(as_xml.xpath('no-mac-learning')){ as_hash[:no_mac_learning] = true }
    return true
  end
  
  ### ---------------------------------------------------------------
  ### XML writers
  ### ---------------------------------------------------------------
  
  def xml_change_no_mac_learning( xml )
    no_ml = @should[:no_mac_learning]     
    return unless exists? and no_ml    
    xml.send(:'no-mac-learning', no_ml ? nil : Netconf::JunosConfig::DELETE )
  end
  
  def xml_change_vlan_id( xml )
    xml.send(:'vlan-id', @should[:vlan_id] )
  end
  
  def xml_change_description( xml )
    value = @should[:description]
    xml.description value ? value : Netconf::JunosConfig::DELETE
  end

end

##### ---------------------------------------------------------------
##### Provider collection methods
##### ---------------------------------------------------------------

class Junos::Ez::Vlans::Provider::VLAN
  
  def build_list    
    xml_cfgs = @ndev.rpc.get_configuration{ |x| x.send :'vlans' }
    xml_cfgs.xpath('vlans/vlan').collect do |vlan|
      vlan.xpath('name').text
    end    
  end
  
  def build_catalog
    @catalog = {}    
    xml_cfgs = @ndev.rpc.get_configuration{ |x| x.send :'vlans' }    
    xml_cfgs.xpath('vlans/vlan').collect do |vlan|
      name = vlan.xpath('name').text
      @catalog[name] = {}
      xml_read_parser( vlan, @catalog[name] )
    end          
    return @catalog
  end
  
end

##### ---------------------------------------------------------------
##### Provider operational methods
##### ---------------------------------------------------------------

class Junos::Ez::Vlans::Provider::VLAN

  ### ---------------------------------------------------------------
  ### interfaces - returns a Hash of each interface in the VLAN
  ###    each interface (key) will identify:
  ###    :mode = [ :access | :trunk ]
  ###    :native = true if (:mode == :trunk) and this VLAN is the 
  ###       native vlan-id (untagged packets)
  ### ---------------------------------------------------------------
  
  def interfaces( opts = {} )
    raise ArgumentError, "not a resource" if is_provider?
    
    args = {}
    args[:vlan_name] = @name 
    args[:extensive] = true    
    got = @ndev.rpc.get_vlan_information( args )
    
    members = got.xpath('vlan/vlan-detail/vlan-member-list/vlan-member')
    ifs_h = {}
    members.each do |port|
      port_name = port.xpath('vlan-member-interface').text.split('.')[0]
      port_h = {}
      port_h[:mode] = port.xpath('vlan-member-port-mode').text.to_sym
      native = (port.xpath('vlan-member-tagness').text == 'untagged')
      port_h[:native] = true if( native and port_h[:mode] == :trunk)
      ifs_h[port_name] = port_h
    end
    ifs_h    
  end
end
