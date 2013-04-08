class Junos::Ez::Vlans::Provider::BRIDGE_DOMAIN < Junos::Ez::Vlans::Provider

  ### ---------------------------------------------------------------
  ### XML top placement
  ### ---------------------------------------------------------------
  
  def xml_at_top
    Nokogiri::XML::Builder.new{|x| x.configuration{ 
      x.send( :'bridge-domains' ) { x.domain { x.name @name
        return x
      }}
    }}
  end

  ### ---------------------------------------------------------------
  ### XML readers
  ### ---------------------------------------------------------------

  def xml_read!    
    cfg_xml = @ndev.rpc.get_configuration( xml_at_top )    
    return nil unless (@has_xml = cfg_xml.xpath('//domain')[0])      
    xml_read_parser( @has_xml, @has )    
  end
  
  def xml_read_parser( as_xml, as_hash )
    status_from_junos( as_xml, as_hash )        
    as_hash[:vlan_id] = as_xml.xpath('vlan-id').text.to_i
    as_hash[:description] = as_xml.xpath('description').text
    as_hash[:no_mac_learning] = as_xml.xpath('bridge-options/no-mac-learning').empty? ? false : true    
    return true    
  end
  
  ### ---------------------------------------------------------------
  ### XML writers
  ### ---------------------------------------------------------------

  def xml_on_create( xml )
    xml.send( :'domain-type', 'bridge' )
  end
    
  def xml_change_no_mac_learning( xml )
    no_ml = @should[:no_mac_learning]     
    return unless ( exists? and no_ml )    
    xml.send(:'bridge-options') {
      xml.send(:'no-mac-learning', no_ml ? nil : Netconf::JunosConfig::DELETE )
    }    
  end
  
  def xml_change_vlan_id( xml )
    xml.send( :'vlan-id', @should[:vlan_id] )
  end
  
  def xml_change_description( xml )
    xml.description @should[:description]
  end

end


##### ---------------------------------------------------------------
##### Provider collection methods
##### ---------------------------------------------------------------

class Junos::Ez::Vlans::Provider::BRIDGE_DOMAIN
  
  def build_list    
    bd_cfgs = @ndev.rpc.get_configuration{ |x| x.send :'bridge-domains' }
    bd_cfgs.xpath('bridge-domains/domain').collect do |domain|
      domain.xpath('name').text
    end    
  end
  
  def build_catalog
    @catalog = {}    
    bd_cfgs = @ndev.rpc.get_configuration{ |x| x.send :'bridge-domains' }    
    bd_cfgs.xpath('bridge-domains/domain').collect do |domain|
      name = domain.xpath('name').text
      @catalog[name] = {}
      xml_read_parser( domain, @catalog[name] )
    end          
    return @catalog
  end
  
end

