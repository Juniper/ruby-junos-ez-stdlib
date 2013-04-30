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

    as_hash[:admin] = as_xml.xpath('disable').empty? ? :up : :down    
    ifa_inet = as_xml.xpath('family/inet')
    
    xml_when_item(as_xml.xpath('vlan-id')){ |i| as_hash[:tag_id] = i.text.to_i }
    xml_when_item(as_xml.xpath('description')){ |i| as_hash[:description] = i.text }
    xml_when_item(ifa_inet.xpath('mtu')){ |i| as_hash[:mtu] = i.text.to_i }   
    
    # @@@ assuming a single IP address; prolly need to be more specific ...
    as_hash[:address] = ifa_inet.xpath('address/name').text || nil
    
    # check for firewall-filters (aka ACLs)
    if (fw_acl = ifa_inet.xpath('filter')[0])
      xml_when_item( fw_acl.xpath('input/filter-name')){ |i| as_hash[:acl_in] = i.text.strip }
      xml_when_item( fw_acl.xpath('output/filter-name')){ |i| as_hash[:acl_out] = i.text.strip }
    end
    
    return true
  end  
  
  ### ---------------------------------------------------------------
  ### XML writers
  ### ---------------------------------------------------------------
  
  def xml_change_address( xml )
    xml.family { xml.inet {
      # delete the old address and replace it with the new one ...
      if @has[:address]
        xml.address( Netconf::JunosConfig::DELETE ) { xml.name @has[:address] }
      end
      xml.address { xml.name @should[:address] }
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
  
  def xml_change_acl_in( xml )
    xml.family { xml.inet { xml.filter { xml.input {
      xml_set_or_delete( xml, 'filter-name', @should[:acl_in] )
    }}}}
  end
  
  def xml_change_acl_out( xml )
    xml.family { xml.inet { xml.filter { xml.output {
      xml_set_or_delete( xml, 'filter-name', @should[:acl_out] )      
    }}}}    
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
