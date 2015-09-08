require "junos-ez/provider"

module Junos::Ez::LAGports

  PROPERTIES = [ 
    :links,               # Set of interface names  
    :minimum_links,       # nil or Number > 0 # optional
    :lacp,                # [ :active, :passive, :disabled ] # optional
  ]  
  
  def self.Provider( ndev, varsym )            
    newbie = Junos::Ez::LAGports::Provider::new( ndev )            
    newbie.properties = Junos::Ez::Provider::PROPERTIES + PROPERTIES
    Junos::Ez::Provider.attach_instance_variable( ndev, varsym, newbie )
  end
  
  class Provider < Junos::Ez::Provider::Parent
    # common parenting goes here ... if we were to
    # subclass the objects ... not doing that now
  end
  
end

class Junos::Ez::LAGports::Provider 
  
  ### ---------------------------------------------------------------
  ### XML top placement
  ### ---------------------------------------------------------------
  
  # LAG ports sit at the toplevel interface
  
  def xml_at_top
    Nokogiri::XML::Builder.new {|xml| xml.configuration {
      xml.interfaces { xml.interface {
        xml.name @name
        return xml
      }}
    }}
  end
  
  ###-----------------------------------------------------------
  ###-----------------------------------------------------------
  ### utilities
  ###-----------------------------------------------------------

  def get_cookie_links( cfg )
    cfg.xpath( "apply-macro[name = 'netdev_lag[:links]']/data/name" ).collect { |n| n.text }
  end 

  def set_cookie_links( cfg )
    cfg.send(:'apply-macro', Netconf::JunosConfig::REPLACE ) {
      cfg.name 'netdev_lag[:links]'
      should[:links].each{ |ifd|
        cfg.data { cfg.name ifd }
      }
    }
  end  
       
  ### ---------------------------------------------------------------
  ### XML property readers
  ### ---------------------------------------------------------------  
  
  def xml_config_read!
    database = {'database' => 'committed'}
    @ndev.rpc.get_configuration(xml_at_top, database)
  end
 
  def xml_get_has_xml( xml )
    if ndev.facts[:ifd_style] == "CLASSIC"
      @ifd_ether_options = 'gigether-options'
    else
      @ifd_ether_options = 'ether-options' 
    end 
    xml.xpath('//interface')[0]    
  end
  
  def xml_read_parser( as_xml, as_hash )    
    set_has_status( as_xml, as_hash )          
        
    # property :links
    ae_name = as_xml.xpath('name').text
    as_hash[:links] = Set.new(get_cookie_links(as_xml))
    
    # property :lacp
    ae_opts = as_xml.xpath('aggregated-ether-options')
    if (lacp = ae_opts.xpath('lacp')[0])
      as_hash[:lacp] = (lacp.xpath('active')[0]) ? :active : :passive
    else
      as_hash[:lacp] = :disabled
    end      
    
    # property :minimum_links
    as_hash[:minimum_links] = (min_links = ae_opts.xpath('minimum-links')[0]) ? min_links.text.to_i : 1
  end
    
  ### ---------------------------------------------------------------
  ### XML property writers
  ### ---------------------------------------------------------------    
  def update_ifd_should()
    if @should[:links].empty?
      raise Junos::Ez::NoProviderError, "\n *links* are compulsory for creating lag interface!!! \n"
    else
      ether_option = @should[:links][0].to_s
      @ifd_ether_options = (ether_option.start_with? 'fe-') ? 'fastether-options' : 'gigether-options'
    end
  end
 
  def update_ifd_has()
    @has[:links] = @has[:links].to_a
    if @has[:links].empty?
     raise Junos::Ez::NoProviderError, "\n Either lag interface is not created or links associated with given lag interface is not supported \n"
    else
     ether_option = @has[:links][0].to_s
     @ifd_ether_options = (ether_option.start_with? 'fe-') ? 'fastether-options' : 'gigether-options'
    end  
  end
 
  def xml_change_links( xml )
    update_ifd_should()  
    @should[:links] = @should[:links].to_set if @should[:links].kind_of? Array
    
    has = @has[:links] || Set.new
    should = @should[:links] || Set.new
            
    set_cookie_links( xml )

    del = has - should
    add = should - has
    
    par = xml.instance_variable_get(:@parent)
    dot_ifd = par.at_xpath('ancestor::interfaces')

    add.each{ |new_ifd| Nokogiri::XML::Builder.with( dot_ifd ) {|dot|
      dot.interface { dot.name new_ifd
        dot.send(@ifd_ether_options.to_sym) {
          dot.send(:'ieee-802.3ad') {
            dot.bundle @name
          }
        }
    }}}

    del.each{ |new_ifd| Nokogiri::XML::Builder.with( dot_ifd ) {|dot|
      dot.interface { dot.name new_ifd
        dot.send(@ifd_ether_options) {
          dot.send( :'ieee-802.3ad', Netconf::JunosConfig::DELETE )
        }
    }}} 
  end
  
  def xml_change_lacp( xml )
    if @should[:lacp] == :disabled or @should[:lacp].nil?
      xml.send(:'aggregated-ether-options') {
        xml.lacp( Netconf::JunosConfig::DELETE )
      }
    else
      xml.send(:'aggregated-ether-options') {
        xml.lacp { xml.send @should[:lacp] }      # @@@ should validate :lacp value before doing this...
      }
    end
  end
  
  def xml_change_minimum_links( xml )
    if @should[:minimum_links] 
      xml.send(:'aggregated-ether-options') {
        xml.send( :'minimum-links', @should[:minimum_links] )
      }
    else
      xml.send(:'aggregated-ether-options') {
        xml.send(:'minimum-links', Netconf::JunosConfig::DELETE )
      }
    end
  end
  
  ### ---------------------------------------------------------------
  ### XML on-create
  ### ---------------------------------------------------------------  
  
  def xml_on_create( xml )
    # make sure there is a 'unit 0' on the AE port
    par = xml.instance_variable_get(:@parent)
    Nokogiri::XML::Builder.with(par) do |dot|
      dot.unit {
        dot.name '0'
      }
    end
  end
  
  ### ---------------------------------------------------------------
  ### XML on-delete
  ### ---------------------------------------------------------------      
  
  def xml_on_delete( xml )
    update_ifd_has()
    par = xml.instance_variable_get(:@parent)
    dot_ifd = par.at_xpath('ancestor::interfaces')
   
    # remove the bindings from each of the physical interfaces
    #    
    @has[:links].each do |new_ifd| Nokogiri::XML::Builder.with( dot_ifd ) do |dot|
      dot.interface { dot.name new_ifd
        dot.send(@ifd_ether_options) {
          dot.send( :'ieee-802.3ad', Netconf::JunosConfig::DELETE )
        }
      }
      end
    end
    
    # now remove the LAG interface
    #
    Nokogiri::XML::Builder.with( dot_ifd ) do |dot|
      dot.interface( Netconf::JunosConfig::DELETE ) {
        dot.name @name
      }
    end        
  end
   
end


##### ---------------------------------------------------------------
##### Provider collection methods
##### ---------------------------------------------------------------

class Junos::Ez::LAGports::Provider
  
  def build_list    
    @ndev.rpc.get_interface_information(
      :terse => true,
      :interface_name => 'ae*' 
    ).xpath('physical-interface/name').collect{ |name| name.text.strip }
  end
  
  def build_catalog
    return @catalog if list!.empty?
    
    list.each do |ae_name|
      @ndev.rpc.get_configuration{ |xml|
        xml.interfaces {
          xml.interface {
            xml.name ae_name
          }
        }
      }.xpath('interfaces/interface').each do |as_xml|
        @catalog[ae_name] = {}
        xml_read_parser( as_xml, @catalog[ae_name] )
      end
    end    
    
    @catalog
  end
  
end

##### ---------------------------------------------------------------
##### _PRIVATE methods
##### ---------------------------------------------------------------

class Junos::Ez::LAGports::Provider
  def _get_port_list( name )
    @ndev.rpc.get_interface_information(
      :detail => true,
      :interface_name => name + '.0'
    ).xpath('//lag-link/name').collect{ |name| 
      name.text.strip.split('.',2).first 
    }
  end
end

