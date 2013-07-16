require "junos-ez/provider"

module Junos::Ez::L1ports

  PROPERTIES = [ 
    :admin,               # [ :up, :down ]
    :description,         # string
    :mtu,                 # number
    :speed,               # [ :auto, '10m', '100m', '1g', '10g' ]
    :duplex,              # [ :auto, :half, :full ]
    :unit_count,          # number of configured units
  ]  
  
  IFS_NAME_FILTER = '[fgx]e-*'

  def self.Provider( ndev, varsym )            
    newbie = case ndev.fact( :ifd_style )
    when :SWITCH
      Junos::Ez::L1ports::Provider::SWITCH.new( ndev )            
    when :CLASSIC
      Junos::Ez::L1ports::Provider::CLASSIC.new( ndev )      
    end      
    
    newbie.properties = Junos::Ez::Provider::PROPERTIES + PROPERTIES
    Junos::Ez::Provider.attach_instance_variable( ndev, varsym, newbie )
  end
  
end

class Junos::Ez::L1ports::Provider < Junos::Ez::Provider::Parent
  
  ### ---------------------------------------------------------------
  ### XML readers
  ### ---------------------------------------------------------------

  def xml_get_has_xml( xml )
    xml.xpath('//interface')[0]
  end
    
  def xml_change_mtu( xml )
    xml_set_or_delete( xml, 'mtu', @should[:mtu] )
  end
  
  ### ---------------------------------------------------------------
  ###  Collection methods
  ### ---------------------------------------------------------------  
  
  def build_list
    @ndev.rpc.get_interface_information({
        :media => true,
        :terse => true,
        :interface_name => Junos::Ez::L1ports::IFS_NAME_FILTER
    }).xpath('physical-interface/name').collect do |ifs|
      ifs.text.strip
    end
  end
  
  def build_catalog
    @catalog = {}
    
    # we could have a large list of interfaces, so
    # we need to break this up into individual "gets"
    
    list!.each do |ifs_name|
      @ndev.rpc.get_configuration{ |xml|
        xml.interfaces {
          xml.interface {
            xml.name ifs_name
            xml_read_filter( xml )
          }
        }
      }.xpath('interfaces/interface').each do |ifs_xml|
        @catalog[ifs_name] = {}
        xml_read_parser( ifs_xml, @catalog[ifs_name] )
      end
    end
    
    return @catalog
  end
  
  ### ---------------------------------------------------------------
  ###  Resource methods
  ### ---------------------------------------------------------------  
  
  ## returns a Hash of status information, from "show interface ..."
  ## basic information, not absolutely everything.  but if a 
  ## block is given, then pass the XML to the block.
  
  def status
    
    got = @ndev.rpc.get_interface_information(:interface_name => @name, :media => true )
    phy = got.xpath('physical-interface')[0]
    return nil unless phy
    
    ret_h = {}
    ret_h[:macaddr] = phy.xpath('current-physical-address').text.strip 
    xml_when_item(phy.xpath('description')){|i| ret_h[:description] = i.text.strip }
    ret_h[:oper_status] = phy.xpath('oper-status').text.strip
    ret_h[:admin_status] = phy.xpath('admin-status').text.strip
    ret_h[:mtu] = phy.xpath('mtu').text.to_i
    ret_h[:speed] = {:admin => phy.xpath('speed').text.strip }
    ret_h[:duplex] = {:admin => phy.xpath('duplex').text.strip }
    ret_h[:autoneg] = phy.xpath('if-auto-negotiation').text.strip 
    
    if ret_h[:autoneg] == "enabled"
      autoneg = phy.xpath('ethernet-autonegotiation')[0]
      ret_h[:speed][:oper] = autoneg.xpath('link-partner-speed').text.strip
      ret_h[:duplex][:oper] = autoneg.xpath('link-partner-duplexity').text.strip
    end
    
    # if a block is given, then it means the caller wants to process the XML data.
    yield( phy ) if block_given?
    
    ret_h
  end
  
end  

require 'junos-ez/l1_ports/switch'
require 'junos-ez/l1_ports/classic'

