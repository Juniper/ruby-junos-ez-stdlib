class Junos::Vlans::VLAN < Junos::Provides::Parent
  
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

  def read!
    cfg_xml = @ndev.rpc.get_configuration( xml_at_top )
    return nil unless (@has_xml = cfg_xml.xpath('//vlan')[0])  
    status_from_junos( @has_xml )    
    xml_read_parse
  end
  
  def xml_read_parse
    @has[:vlan_id] = @has_xml.xpath('vlan-id').text.to_i
    @has[:description] = @has_xml.xpath('description').text
    @has[:no_mac_learning] = @has_xml.xpath('no-mac-learning').empty? ? false : true
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
