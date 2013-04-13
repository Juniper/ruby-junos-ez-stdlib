class Junos::Ez::IPports::Provider::CLASSIC < Junos::Ez::IPports::Provider
  
  ### ---------------------------------------------------------------
  ### XML top placement
  ### ---------------------------------------------------------------
  
  def xml_at_top    
    
    # if just the IFD is given as the name, default to unit "0"
    @ifd, @ifl = @name.split '.'
    @ifl ||= "0"
    
    Nokogiri::XML::Builder.new{ |x| x.configuration{ 
      x.interfaces { x.interface { x.name @ifd
        x.unit {
          x.name @ifl
          return x
        }
      }}
    }}
  end
  
  def xml_element_rename( new_name )
    
    # if just the IFD is given as the name, default to unit "0"
    n_ifd, n_ifl = new_name.split '.'
    n_ifl ||= "0"
    
    # do not allow rename to different IFD.
    return false unless @ifd == n_ifd
    
    # return the new element name
    return n_ifl
  end
  
  ### ---------------------------------------------------------------
  ### XML readers
  ### ---------------------------------------------------------------

  def xml_get_has_xml( xml )
    xml.xpath('//unit')[0]
  end
    
  def xml_read_parser( as_xml, as_hash )
    set_has_status( as_xml, as_hash )    
    
    ifa_inet = as_xml.xpath('family/inet')
    
    as_hash[:tag_id] = as_xml.xpath('vlan-id').text.to_i
    as_hash[:description] = as_xml.xpath('description').text
    as_hash[:mtu] = ifa_inet.xpath('mtu').text.to_i || nil
    as_hash[:address] = ifa_inet.xpath('address/name').text || nil
    as_hash[:admin] = as_xml.xpath('disable').empty? ? :up : :down
    
    return true
  end  
  
  ### ---------------------------------------------------------------
  ### XML writers
  ### ---------------------------------------------------------------
  
  def xml_change_address( xml )
    xml.family { xml.inet {
      if @has[:address]
        xml.address( Netconf::JunosConfig::DELETE ) {
          xml.name @has[:address]
        }
      end
      xml.address { 
        xml.name @should[:address] 
      }
    }}
  end
  
  def xml_change_tag_id( xml )
    xml_set_or_delete( xml, 'vlan-id', @should[:tag_id] )
  end

  def xml_change_mtu( xml )
    xml.family { xml.inet {
      xml_set_or_delete( xml, 'mtu', @should[:mtu] )
    }}
  end   

end

##### ---------------------------------------------------------------
##### Provider collection methods
##### ---------------------------------------------------------------

class Junos::Ez::IPports::Provider::CLASSIC
  
  def build_list            
    from_junos_get_ifa_xml.collect do |ifa|
      ifa.xpath('name').text.strip
    end                
  end
  
  def build_catalog
    @catalog = {}

    ## do the equivalent of "show interfaces ..." to retrieve the list
    ## of known interfaces that have an IFA == 'inet'.  Note that this
    ## list will *not* include anything that has been deactivated.
    
    ifa_list = from_junos_get_ifa_xml
    
    ## from this list of IFA, retrieve the configurations
    
    got_xml_cfg = @ndev.rpc.get_configuration do |cfg|
      cfg.interfaces {
        ifa_list.each do |ifa|
          ifa_name = ifa.xpath('name').text.strip
          ifa_ifd, ifa_ifl = ifa_name.split '.'
          cfg.interface { 
            cfg.name ifa_ifd 
            cfg.unit { cfg.name ifa_ifl }
          }
        end
      }
    end    
    
    ## now create the object property hashes for each of the instances
    
    got_xml_cfg.xpath('interfaces/interface/unit').each do |ifl|      
      ifd = ifl.xpath('preceding-sibling::name').text.strip
      unit = ifl.xpath('name').text.strip
      obj_name = ifd + '.' + unit
      
      @catalog[obj_name] = {}
      xml_read_parser( ifl, @catalog[obj_name] )
    end
    
    return @catalog
  end
  
  private
  
  def from_junos_get_ifa_xml
    
    xml_data = @ndev.rpc.get_interface_information( 
      :terse => true,
      :interface_name => '[xgf]e-*/*/*.*' )
    
    ifa_list = xml_data.xpath('logical-interface[normalize-space(address-family/address-family-name) = "inet"]')    
    
  end
  
end
