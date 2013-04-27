=begin
=end

module Junos::Ez::UserAuths

  PROPERTIES = [ 
    :publickey            # String
  ]  
  
  VALID_KEY_TYPES = ['ssh-rsa','ssh-dss']

  def self.Provider( ndev, varsym )            
    newbie = Junos::Ez::UserAuths::Provider.new( ndev )            
    newbie.properties = Junos::Ez::Provider::PROPERTIES + PROPERTIES
    Junos::Ez::Provider.attach_instance_variable( ndev, varsym, newbie )
  end
  
  class Provider < Junos::Ez::Provider::Parent
  end
    
end

##### ---------------------------------------------------------------
##### Resource Property Methods
##### ---------------------------------------------------------------

class Junos::Ez::UserAuths::Provider
  
  ### ---------------------------------------------------------------
  ### XML top placement
  ### ---------------------------------------------------------------
  
  def xml_at_top
    Nokogiri::XML::Builder.new{|x| x.configuration{ 
      x.system { x.login { x.user { 
        x.name @name[:user]
        x.authentication {          
          x.send( @name[:keytype].to_sym ) {
            x.name @name[:publickey]
            return x
          }
        }
      }}}
    }}
  end
  
  ### ---------------------------------------------------------------
  ### XML readers
  ### ---------------------------------------------------------------

  def xml_get_has_xml( xml )
    xml.xpath('//user/authentication/*')[0]
  end
        
  def xml_read_parser( as_xml, as_hash )
    set_has_status( as_xml, as_hash )     
    as_hash[:publickey] = as_xml.xpath('name').text.strip
  end    
  
  ### ---------------------------------------------------------------
  ### XML writers
  ### ---------------------------------------------------------------  
  
  def xml_change_publickey( xml )
    true
  end

end

##### ---------------------------------------------------------------
##### Provider Collection Methods
##### ---------------------------------------------------------------

class Junos::Ez::UserAuths::Provider
  def build_list
    []
  end
  
  def build_catalog
    {}
  end
end


