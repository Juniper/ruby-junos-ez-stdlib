class Junos::Ez::L1ports::Provider::CLASSIC < Junos::Ez::L1ports::Provider

  ### ---------------------------------------------------------------
  ### XML top placement
  ### ---------------------------------------------------------------
  
  def xml_at_top
    xml = Nokogiri::XML::Builder.new {|xml| xml.configuration {
      xml.interfaces {
        xml.interface { 
          xml.name name
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
    xml.speed
    xml.send(:'link-mode') 
    xml.unit({:recurse => 'false'})    
  end
  
  def xml_config_read!
    xml = xml_at_top
    xml_read_filter( xml )
    @ndev.rpc.get_configuration( xml )      
  end    

  def xml_read_parser( as_xml, as_hash )    
    set_has_status( as_xml, as_hash )

    as_hash[:admin] = as_xml.xpath('disable').empty? ? :up : :down
    
    unless (desc = as_xml.xpath('description').text.chomp).empty?
      as_hash[:description] = desc
    end
        
    if mtu = as_xml.xpath('mtu')[0]; as_hash[:mtu] = mtu.text.to_i end
            
    as_hash[:duplex] = case as_xml.xpath('link-mode').text.chomp
      when 'full-duplex' then :full
      when 'half-duplex' then :half
      else :auto
    end
      
    as_hash[:speed] = ( speed = as_xml.xpath('speed')[0] ) ? speed.text : :auto         
    as_hash[:unit_count] = as_xml.xpath('unit').count
    
    return true
  end
  
  ### ---------------------------------------------------------------
  ### XML property writers
  ### ---------------------------------------------------------------
  
  def xml_change_speed( xml )
    if @should[:speed] == :auto
      if is_new?
        xml.speed Netconf::JunosConfig::DELETE
      end
    else
      xml.speed @should[:speed]
    end
  end  

  def xml_change_duplex( xml )
    if @should[:duplex] == :auto
      unless is_new?
        xml.send( :'link-mode', Netconf::JunosConfig::DELETE )
      end
    else
      xml.send( :'link-mode', case @should[:duplex]
        when :full then 'full-duplex'
        when :half then 'half-duplex'
        end )
    end
  end  
    
end
