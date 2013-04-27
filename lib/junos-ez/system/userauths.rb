=begin
=end

module Junos::Ez::UserAuths
  
  VALID_KEY_TYPES = ['ssh-rsa','ssh-dsa']

  def self.Provider( ndev, varsym )            
    newbie = Junos::Ez::UserAuths::Provider.new( ndev )            
    newbie.properties = Junos::Ez::Provider::PROPERTIES
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
    @should[:_active] = true              # mark it so it will write!    
    xml.xpath('//user/authentication/*')[0]    
  end
        
  def xml_read_parser( as_xml, as_hash )
    set_has_status( as_xml, as_hash )
  end    
  
  ### ---------------------------------------------------------------
  ### XML writers
  ### ---------------------------------------------------------------
  
  ## !! since we're not actually modifying any properties, we need
  ## !! to overload the xml_build_change method to simply return
  ## !! the config at-top (includes ssh name)
  
  def xml_build_change( xml_at_here = nil )
    xml_at_top.doc.root
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


