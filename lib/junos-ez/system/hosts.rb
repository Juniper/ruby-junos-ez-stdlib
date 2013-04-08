class Junos::Ez::Hosts::Provider
  
  ### ---------------------------------------------------------------
  ### XML top placement
  ### ---------------------------------------------------------------
  
  def xml_at_top
    xml = Nokogiri::XML::Builder.new {|xml| xml.configuration {
      xml.system { xml.send('static-host-mapping') {
        xml.name @name
        return xml
      }}
    }}
  end
  
  ### ---------------------------------------------------------------
  ### XML property readers
  ### ---------------------------------------------------------------  

  def xml_get_has_xml( xml )  
    xml.xpath('//static-host-mapping')[0]
  end
  
  def xml_read_parser( as_xml, as_hash )    
    set_has_status( as_xml, as_hash )  
    
    ip_v4 = as_xml.xpath('inet').text
    as_hash[:ip] = ip_v4 unless ip_v4.empty?
    
    ip_v6 = as_xml.xpath('inet6').text
    as_hash[:ip6] = ip_v6 unless ip_v6.empty?
  end
  
  ### ---------------------------------------------------------------
  ### XML property writers
  ### ---------------------------------------------------------------  
  
  def xml_change_ip( xml )
    xml_set_or_delete( xml, 'inet', @should[:ip] )
  end
  
  def xml_change_ip6( xml )
    xml_set_or_delete( xml, 'inet6', @should[:ip6] )
  end  
  
end

##### ---------------------------------------------------------------
##### Provider collection methods
##### ---------------------------------------------------------------

class Junos::Ez::Hosts::Provider
  
  def build_list
    @ndev.rpc.get_configuration{|xml| xml.system {
      xml.send(:'static-host-mapping')
    }}.xpath('system/static-host-mapping/name').collect do |item|
      item.text
    end    
  end
  
  def build_catalog
    @catalog = {}
    @ndev.rpc.get_configuration{ |xml| xml.system {
      xml.send(:'static-host-mapping')
    }}.xpath('system/static-host-mapping').each do |item|
      name = item.xpath('name').text
      @catalog[name] = {}
      xml_read_parser( item, @catalog[name] )
    end    
    @catalog
  end
  
end
