class Junos::Ez::StaticRoutes::Provider
  
  ### ---------------------------------------------------------------
  ### XML top placement
  ### ---------------------------------------------------------------
  
  def xml_at_top
    @name = "0.0.0.0/0" if @name == :default
    
    Nokogiri::XML::Builder.new {|xml| xml.configuration {
      xml.send('routing-options') {
        xml.static { xml.route {
          xml.name @name
          return xml
        }}
      }
    }}
  end
    
  ### ---------------------------------------------------------------
  ### XML property readers
  ### ---------------------------------------------------------------  

  def xml_get_has_xml( xml )  
    xml.xpath('routing-options/static/route')[0]
  end
  
  def xml_read_parser( as_xml, as_hash )    
    set_has_status( as_xml, as_hash )
    
    ## :gateway
    unless (next_hop = as_xml.xpath('next-hop')).empty?
      if next_hop.count == 1
        as_hash[:gateway] = next_hop.text    
      else
        as_hash[:gateway] = next_hop.collect{|i| i.text }
      end
    end
    
    unless (active = as_xml.xpath('active')).empty?
      as_hash[:active] = true
    end
    
    unless (action = as_xml.xpath( 'reject | discard | receive' )).empty?
      as_hash[:action] = action[0].name.to_sym
    end
    
    unless (metric = as_xml.xpath('metric')).empty?
      as_hash[:metric] = metric.text.to_i
    end
    
    xml_read_parse_noele( as_xml, 'retain', as_hash, :retain )
    xml_read_parse_noele( as_xml, 'install', as_hash, :install )
    xml_read_parse_noele( as_xml, 'resolve', as_hash, :resolve )
    xml_read_parse_noele( as_xml, 'readvertise', as_hash, :readvertise )        
  end
  
  
  ### ---------------------------------------------------------------
  ### XML property writers
  ### ---------------------------------------------------------------  
    
  def xml_change_action( xml )
    
    if @should[:action].nil?
      xml.send( @has[:action], Netconf::JunosConfig::DELETE )
      return true
    end
    
    xml.send( @should[:action] )
  end
  
  def xml_change_active( xml )
    xml_set_or_delete_element( xml, 'active', @should[:active] )
  end
  
  def xml_change_gateway( xml )
    # delete existing entries
    ele_nh = :'next-hop'    
    
    # clear any existing values, and return unless there are any new ones ...
    xml.send(ele_nh, Netconf::JunosConfig::DELETE) if @has[:gateway]    
    return true unless @should[:gateway]      
    
    ## adding back the ones we want now ... 
    if @should[:gateway].kind_of? String
      xml.send( ele_nh, @should[:gateway] )
    else       
      @should[:gateway].each{ |gw| xml.send( ele_nh, gw ) }
    end
  end
  
  def xml_change_retain( xml )
    xml_set_or_delete_noele( xml, 'retain' )
  end
  
  def xml_change_install( xml )
    xml_set_or_delete_noele( xml, 'install' )
  end
  
  def xml_change_resolve( xml )
    xml_set_or_delete_noele( xml, 'resolve' )
  end
  
  def xml_change_readvertise( xml )
    xml_set_or_delete_noele( xml, 'readvertise' )
  end
  
  def xml_change_metric( xml )
    xml_set_or_delete( xml, 'metric', @should[:metric] )
  end
  
    
end

##### ---------------------------------------------------------------
##### Provider collection methods
##### ---------------------------------------------------------------

class Junos::Ez::StaticRoutes::Provider
  
  def build_list
    @ndev.rpc.get_configuration{|xml| xml.send(:'routing-options') {
      xml.static { xml.route }
    }}.xpath('//route/name').collect do |item|
      item.text
    end    
  end
  
  def build_catalog
    @catalog = {}
    @catalog
  end
  
end
