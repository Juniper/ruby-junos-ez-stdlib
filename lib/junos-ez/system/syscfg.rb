class Junos::Ez::SysConfig::Provider 
  
  ### ---------------------------------------------------------------
  ### XML top placement
  ### ---------------------------------------------------------------
  
  def xml_at_top
    xml = Nokogiri::XML::Builder.new {|xml| xml.configuration {
      xml.system {
        return xml
      }
    }}
  end
  
  def xml_config_read!    
    xml = xml_at_top
    xml.send(:'host-name')
    xml.send(:'domain-name')
    xml.send(:'domain-search')
    xml.send(:'time-zone')
    xml.location
    xml.send(:'name-server')
    xml.ntp
    @ndev.rpc.get_configuration( xml )
  end
  
  ### ---------------------------------------------------------------
  ### XML property readers
  ### ---------------------------------------------------------------  

  def xml_get_has_xml( xml )  
    xml.xpath('system')[0]
  end
  
  def xml_read_parser( as_xml, as_hash )    
    set_has_status( as_xml, as_hash )      
    as_hash[:host_name] = as_xml.xpath('host-name').text
    unless (data = as_xml.xpath('domain-name')).empty?
      as_hash[:domain_name] = data.text
    end
    unless (data = as_xml.xpath('domain-search')).empty?
      as_hash[:domain_search] = data.collect{|i| i.text}
    end
    unless (data = as_xml.xpath('time-zone')).empty?
      as_hash[:timezone] = data.text
    end
    unless (data = as_xml.xpath('name-server/name')).empty?
      as_hash[:dns_servers] = data.collect{|i| i.text}
    end
    unless (data = as_xml.xpath('ntp/server/name')).empty?
      as_hash[:ntp_servers] = data.collect{|i| i.text}
    end
    unless (location = as_xml.xpath('location')).empty?
      as_hash[:location] = {}  
      unless (data = location.xpath('building')).empty?
        as_hash[:location][:building] = data.text
      end
      unless (data = location.xpath('country-code')).empty?
        as_hash[:location][:countrycode] = data.text
      end
      unless (data = location.xpath('floor')).empty?
        as_hash[:location][:floor] = data.text
      end
      unless (data = location.xpath('rack')).empty?
        as_hash[:location][:rack] = data.text
      end
    end
  end
  
  ### ---------------------------------------------------------------
  ### XML property writers
  ### ---------------------------------------------------------------    
  
  def xml_change_host_name( xml )
    xml.send(:'host-name', @should[:host_name] )
  end

  def xml_change_domain_name( xml )
    xml.send(:'domain-name', @should[:domain_name] )
  end

  def xml_change_domain_search( xml )
  end
  
  def xml_change_timezone( xml )
    xml.send(:'time-zone', @should[:timezone])
  end
  
  def xml_change_dns_servers( xml )
  end
  
  def xml_change_ntp_servers( xml )
  end
  
  def xml_change_date( xml )
  end
  
  def xml_change_location( xml )
  end
    
end


