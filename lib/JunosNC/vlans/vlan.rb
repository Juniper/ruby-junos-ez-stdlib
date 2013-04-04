class JunosNC::Vlans::Provider::VLAN < JunosNC::Vlans::Provider
  
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

  def xml_read!    
    cfg_xml = @ndev.rpc.get_configuration( xml_at_top )
    return nil unless (@has_xml = cfg_xml.xpath('//vlan')[0])  
    xml_read_parser( @has_xml, @has )  
  end
  
  def xml_read_parser( as_xml, as_hash )
    status_from_junos( as_xml, as_hash )    
    as_hash[:vlan_id] = as_xml.xpath('vlan-id').text.to_i
    as_hash[:description] = as_xml.xpath('description').text
    as_hash[:no_mac_learning] = as_xml.xpath('no-mac-learning').empty? ? false : true    
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

class JunosNC::Vlans::Provider::VLAN
  
  def list!    
    xml_cfgs = @ndev.rpc.get_configuration{ |x| x.send :'vlans' }
    xml_cfgs.xpath('vlans/vlan').collect do |vlan|
      vlan.xpath('name').text
    end    
  end
  
  def catalog!
    catalog = {}    
    xml_cfgs = @ndev.rpc.get_configuration{ |x| x.send :'vlans' }    
    xml_cfgs.xpath('vlans/vlan').collect do |vlan|
      name = vlan.xpath('name').text
      props = Hash.new
      xml_read_parser( vlan, props )
      catalog[name] = props
    end          
    return catalog
  end
  
end
