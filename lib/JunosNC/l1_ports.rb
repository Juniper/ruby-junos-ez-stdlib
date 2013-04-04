require "JunosNC/provider"

module JunosNC::L1ports

  PROPERTIES = [ 
    :admin,               # [ :up, :down ]
    :description,         # string
    :mtu,                 # number
    :speed,               # [ :auto, '10m', '100m', '1g', '10g' ]
    :duplex,              # [ :auto, :half, :full ]
    :unit_count,          # number of configured units
  ]  

  def self.Provider( ndev, varsym )            
    newbie = case ndev.fact( :ifd_style )
    when :VLAN
      JunosNC::L1ports::Provider::VLAN.new( ndev )            
    when :CLASSIC
      JunosNC::L1ports::Provider::CLASSIC.new( ndev )      
    end      
    
    newbie.properties = JunosNC::Provider::PROPERTIES + PROPERTIES
    JunosNC::Provider.attach_instance_variable( ndev, varsym, newbie )
  end
  
end

class JunosNC::L1ports::Provider < JunosNC::Provider::Parent
  
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
        :interface_name => '[fgx]e-*'
    }).xpath('physical-interface/name').collect do |ifs|
      ifs.text.strip
    end
  end
  
  def build_catalog
    @catalog = {}
    
    @ndev.rpc.get_configuration{|xml|
      xml.interfaces {
        list!.each do |ifs|
          xml.interface {
            xml.name ifs
            xml_read_filter( xml )
          }
        end
      }
    }.xpath('interfaces/interface').each do |ifs_xml|
      ifs_name = ifs_xml.xpath('name').text
      @catalog[ifs_name] = {}
      xml_read_parser( ifs_xml, @catalog[ifs_name] )
    end
    
    return @catalog
  end
  
end  

require 'JunosNC/l1_ports/vlan'
require 'JunosNC/l1_ports/classic'

