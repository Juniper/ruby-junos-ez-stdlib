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
