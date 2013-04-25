class Junos::Ez::L1ports::Provider::SWITCH < Junos::Ez::L1ports::Provider

  ### ---------------------------------------------------------------
  ### XML top placement
  ### ---------------------------------------------------------------
  
  def xml_at_top
    xml = Nokogiri::XML::Builder.new {|xml| xml.configuration {
      xml.interfaces {
        xml.interface { 
          xml.name @name
          return xml
        }
      }
    }}
  end
      
  ### ---------------------------------------------------------------
  ### XML property readers
  ### ---------------------------------------------------------------
  
  def xml_read_filter( xml )
    xml.description
    xml.disable
    xml.mtu
    xml.send(:'ether-options') 
    xml.unit({:recurse => 'false'})    
  end
  
  def xml_config_read!
    xml = xml_at_top
    xml_read_filter( xml )
    @ndev.rpc.get_configuration( xml )      
  end    

  def xml_read_parser( as_xml, as_hash )    
    set_has_status( as_xml, as_hash )

    xml_when_item(as_xml.xpath('description')){|i| as_hash[:description] = i.text}        
    as_hash[:admin] = as_xml.xpath('disable').empty? ? :up : :down
    xml_when_item(as_xml.xpath('mtu')){|i| as_hash[:mtu] = i.text.to_i }
        
    phy_options = as_xml.xpath('ether-options')    
    if phy_options.empty?
      as_hash[:speed] = :auto
      as_hash[:duplex] = :auto
    else      
      ## :duplex
      as_hash[:duplex] = case phy_options.xpath('link-mode').text.chomp
        when 'full-duplex' then :full
        when 'half-duplex' then :half
        else :auto
      end
      ## :speed
      if speed = phy_options.xpath('speed')[0]
        as_hash[:speed] = _speed_from_junos_( speed.first_element_child.name )
      else
        as_hash[:speed] = :auto
      end
    end                      
    
    as_hash[:unit_count] = as_xml.xpath('unit').count    
    return true
  end
  
  ### ---------------------------------------------------------------
  ### XML property writers
  ### ---------------------------------------------------------------
  
  def xml_change_speed( xml )
    xml.send(:'ether-options') {
      xml.speed {
        if @should[:speed] == :auto
          unless @has[:speed] == :auto
            xml.send( _speed_to_junos_( @has[:speed] ), Netconf::JunosConfig::DELETE )
          end
        else
          xml.send( _speed_to_junos_( @should[:speed] ))
        end
      }
    }
  end
  
  def xml_change_duplex( xml )
    xml.send(:'ether-options') {
      if @should[:duplex] == :auto
        unless @has[:duplex] == :auto
          xml.send( :'link-mode', Netconf::JunosConfig::DELETE )
        end
      else
        xml.send( :'link-mode', case @should[:duplex]
           when :full then 'full-duplex'
           when :half then 'half-duplex'
        end )
      end
    }
  end  
  
    
end

### -----------------------------------------------------------------
### PRIVATE METHODS
### -----------------------------------------------------------------

class Junos::Ez::L1ports::Provider::SWITCH
  private
  
  def _speed_to_junos_( pval )
    # @@@ TODO: could remove case-statement and to
    # @@@ string processing ...    
    case pval
       when '10g' then :'ethernet-10g'
       when '1g' then :'ethernet-1g'
       when '100m' then :'ethernet-100m'
       when '10m' then :'ethernet-10m'
       else :auto
    end
  end
  
  def _speed_from_junos_( jval )
    # @@@ TODO: could remove case-statement and to
    # @@@ string processing ...
    case jval
      when 'ethernet-100m' then '100m'
      when 'ethernet-10m' then '10m'
      when 'ethernet-1g' then '1g'
      when 'ethernet-10g' then '10g'
      else :auto
    end
  end
  
end

