class Junos::Ez::L2ports::Provider::VLAN < Junos::Ez::L1ports::Provider  
  
  ### ---------------------------------------------------------------
  ### XML top placement
  ### ---------------------------------------------------------------
  
  def xml_at_top
    xml = Nokogiri::XML::Builder.new {|xml| xml.configuration {
      xml.interfaces {
        return xml_at_element_top( xml, @name )
      }
    }}
  end
  
  def xml_at_element_top( xml, name )
    xml.interface {
      xml.name name
      xml.unit { xml.name '0'
        xml.family { xml.send(:'ethernet-switching') {
          return xml
        }}
      }
    }    
  end
  
  ### ---------------------------------------------------------------
  ### XML property readers
  ### ---------------------------------------------------------------  

  def xml_get_has_xml( xml )  
    xml.xpath('//unit')[0]
  end
  
  def xml_read_parser( as_xml, as_hash )    
    set_has_status( as_xml, as_hash )  
    f_eth = as_xml.xpath('family/ethernet-switching')
        
    as_hash[:vlan_tagging] = f_eth.xpath('port-mode').text.chomp == 'trunk' ? :enable : :disable
    xml_when_item(as_xml.xpath('description')){|i| as_hash[:description] = i.text}

    # --- access port        
    if as_hash[:vlan_tagging] == :disable
      as_hash[:untagged_vlan] = f_eth.xpath('vlan/members').text.chomp || ''
      return
    end
    
    # --- trunk port    
    xml_when_item(f_eth.xpath('native-vlan-id')){|i| as_hash[:untagged_vlan] = i.text.chomp }
    as_hash[:tagged_vlans] = f_eth.xpath('vlan/members').collect { |v| v.text.chomp }    
  end
    
  ### ---------------------------------------------------------------
  ### XML property writers
  ### ---------------------------------------------------------------  
  
end

##### ---------------------------------------------------------------
##### Provider collection methods
##### ---------------------------------------------------------------

class Junos::Ez::L2ports::Provider::VLAN
  
  def build_list
    @ndev.rpc.get_ethernet_switching_interface_information(:summary=>true).
      xpath('interface/interface-name').collect{ |ifn| ifn.text.split('.')[0] }
  end
  
  def build_catalog
    @catalog = {}    
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