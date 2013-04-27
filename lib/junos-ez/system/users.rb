=begin
=end

module Junos::Ez::Users

  PROPERTIES = [ 
    :uid,                     # User-ID, Number
    :class,                   # User Class, String
    :fullname,                # Full Name, String
    :password,                # Encrypted password  
  ]  

  def self.Provider( ndev, varsym )            
    newbie = Junos::Ez::Users::Provider.new( ndev )            
    newbie.properties = Junos::Ez::Provider::PROPERTIES + PROPERTIES
    Junos::Ez::Provider.attach_instance_variable( ndev, varsym, newbie )
  end
  
  class Provider < Junos::Ez::Provider::Parent; end
    
end


##### ---------------------------------------------------------------
##### Provider Resource Methods
##### ---------------------------------------------------------------

class Junos::Ez::Users::Provider 
  
  ### ---------------------------------------------------------------
  ### XML top placement
  ### ---------------------------------------------------------------
  
  def xml_at_top
    Nokogiri::XML::Builder.new{|x| x.configuration{ 
      x.system { x.login { x.user { 
        x.name @name
        return x
    }}}}}
  end

  ### ---------------------------------------------------------------
  ### XML readers
  ### ---------------------------------------------------------------

  def xml_get_has_xml( xml )
    xml.xpath('//user')[0]    
  end
        
  def xml_read_parser( as_xml, as_hash )
    set_has_status( as_xml, as_hash )    
    
    as_hash[:uid] = as_xml.xpath('uid').text
    as_hash[:class] = as_xml.xpath('class').text
    
    xml_when_item(as_xml.xpath('full-name')) {|i|
      as_hash[:fullname] = i.text
    }
    
    xml_when_item(as_xml.xpath('authentication/encrypted-password')) {|i|
      as_hash[:password] = i.text
    }    
  end  

  ### ---------------------------------------------------------------    
  ### XML writers
  ### ---------------------------------------------------------------  
  
  def xml_change_password( xml )           
    xml.authentication {
      xml_set_or_delete( xml, 'encrypted-password', @should[:password] )
    }
  end
  
  def xml_change_fullname( xml )     
    xml_set_or_delete( xml, 'full-name', @should[:fullname] )
  end   
  
  # changing the 'gid' is changing the Junos 'class' element
  # so, what is tough here is that the Nokogiri Builder mech
  # won't allow us to use the string 'class' since it conflicts
  # with the Ruby language.  So we need to add the 'class' element
  # the hard way, yo! ...
  
  def xml_change_class( xml )  
    par = xml.instance_variable_get(:@parent)    
    doc = xml.instance_variable_get(:@doc)        
    user_class = Nokogiri::XML::Node.new('class', doc )
    user_class.content = @should[:class]
    par.add_child( user_class )    
  end    
  
  def xml_change_uid( xml )
    xml_set_or_delete( xml, 'uid', @should[:uid] )
  end
  
end

##### ---------------------------------------------------------------
##### Provider Collection Methods
##### ---------------------------------------------------------------

class Junos::Ez::Users::Provider
  
  def build_list
    @ndev.rpc.get_configuration{ |x| x.system {
      x.login {
        x.user({:recurse => 'false'})
      }
    }}
    .xpath('//user/name').collect{ |i| i.text }
  end
  
  def build_catalog
    @catalog = {}
    @ndev.rpc.get_configuration{ |x| x.system {
      x.login {
        x.user
      }
    }}
    .xpath('//user').each do |user|
      name = user.xpath('name').text
      @catalog[name] = {}
      xml_read_parser( user, @catalog[name] )
    end
    @catalog
  end
  
end

##### ---------------------------------------------------------------
##### Provider Resource Methods
##### ---------------------------------------------------------------

class Junos::Ez::Users::Provider
  
  ## ----------------------------------------------------------------
  ## change the password by providing it in plain-text
  ## ----------------------------------------------------------------
  
  def password=(plain_text)
    xml = xml_at_top
    xml.authentication {
      xml.send(:'plain-text-password-value', plain_text)
    }
    @ndev.rpc.load_configuration( xml )
    return true
  end
  
end

