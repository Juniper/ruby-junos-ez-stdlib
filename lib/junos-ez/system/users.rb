=begin
=end

module Junos::Ez::Users

  PROPERTIES = [ 
    :uid,                     # User-ID, Number
    :class,                   # User Class, String
    :fullname,                # Full Name, String
    :password,                # Encrypted password  
    :ssh_keys,                # READ-ONLY, Hash of SSH public keys
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
  
    # READ-ONLY capture the keys
    unless (keys = as_xml.xpath('authentication/ssh-rsa')).empty?
      @has[:ssh_keys] ||= {}
      @has[:ssh_keys]['ssh-rsa'] = keys.collect{|key| key.text.strip}
    end
    unless (keys = as_xml.xpath('authentication/ssh-dsa')).empty?
      @has[:ssh_keys] ||= {}      
      @has[:ssh_keys]['ssh-dsa'] = keys.collect{|key| key.text.strip}
    end
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
##### Resource Methods
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
  
  ## ----------------------------------------------------------------
  ## get a Hash that is used as the 'name' for obtaining a resource
  ## for Junos::Ez::UserAuths
  ## ----------------------------------------------------------------

  def ssh_key_name( keytype, index = 0 )
    return nil unless @has[:ssh_keys]
    return nil unless @has[:ssh_keys][keytype]
    
    ret_h = {:user => @name, :keytype => keytype}
    ret_h[:publickey] = @has[:ssh_keys][keytype][index]
    ret_h
  end
  
  ##
  ## @@ need to move this code into the main provider
  ## @@ as a utility  ...
  ##
  
  def get_userauth_provd
    @ndev.providers.each do |p|
      obj = @ndev.send(p)
      return obj if obj.class == Junos::Ez::UserAuths::Provider
    end
  end
  
  ## ----------------------------------------------------------------
  ## load an SSH public key file that is stored on the local server
  ## into the user account.  Return the resulting key object.
  ## ----------------------------------------------------------------

  def load_ssh_key!( file )
    publickey = File.read( file ).strip
    @auth_provd ||= get_userauth_provd    
    raise StandardError, "No Junos::Ez::UserAuths::Provider" unless @auth_provd
    keytype = publickey[0..6]
    keytype = 'ssh-dsa' if keytype == 'ssh-dss'
    raise ArgumentError, "Unknown ssh key-type #{keytype}" unless ['ssh-rsa','ssh-dsa'].include? keytype
    
    # ok, we've got everything we need to add the key, so here we go.
    key_name = {:user => @name, :keytype => keytype, :publickey => publickey }
    key = @auth_provd[ key_name ]
    key[:publickey] = publickey
    key.write!
    
    # return the key in case the caller wants it
    key
  end
  
end

