=begin
---------------------------------------------------------------------
Loader::Utils is a collection of methods used for loading 
configuration files/templates and software images
---------------------------------------------------------------------
=end

module Junos::Ez::Loader  
  def self.Utils( ndev, varsym )            
    newbie = Junos::Ez::Loader::Provider.new( ndev )      
    Junos::Ez::Provider.attach_instance_variable( ndev, varsym, newbie )    
  end          
end

### -----------------------------------------------------------------
###                        PUBLIC METHODS
### -----------------------------------------------------------------
### -----------------------------------------------------------------

class Junos::Ez::Loader::Provider < Junos::Ez::Provider::Parent
  
  ### ---------------------------------------------------------------
  ### image! - used to load a software image onto device
  ###    suggested usage (for now) is that you use the 'scp'
  ###    method of the Netconf::SSH object to copy the image to the
  ###    device and then use this method to load the image.  
  ###    @@@ TBD, provide copy functionality within this method
  ###    @@@ as convience ...
  ###
  ### --- options --- 
  ###
  ### :filename => path to device local file 
  ### :no_validate => true -- do not validate 
  ### :no_copy => true -- do not save copy of package files
  ### :unlink => true -- remove package after successful install
  ### :reboot => true -- reboot once the loading completes  
  ### ---------------------------------------------------------------
  
  def image!( opts = {} )
  end
  
  ### ---------------------------------------------------------------
  ### config! - used to load configuration files / templates.  This
  ###    does not perform a 'commit', just the equivalent of the
  ###    load-configuration RPC
  ###
  ### --- options ---
  ###
  ### :filename => path - indcates the filename of content
  ###    note: filename extension will also define format
  ###    .conf <==> :text
  ###    .xml  <==> :xml
  ###    .{set,text,txt}  <==> :set
  ### :format =>  [:text, :set, :xml], default :text (curly-brace)
  ###    this will override any auto-format from the :filename
  ### :content => String - string content of data (vs. :filename)
  ### :template  - indicates file/content is an ERB
  ###    => true - used current binding context; i.e. variables
  ###              active in current context/block
  ###    => <object> - will grab the binding from this object
  ###                  using a bit of meta-programming magic
  ###    => <binding> - will use this binding
  ### ---------------------------------------------------------------
  
  def config!( opts = {} )
  end
  
  ### ---------------------------------------------------------------
  ### commit! - commits the configuration to the device
  ### 
  ### options:
  ### :confirmed => timeout 
  ### :comment => commit log comment
  ### ---------------------------------------------------------------
  
  def commit!( opts {} )
  end

  ### ---------------------------------------------------------------
  ### commit? - perform commit configuration check and reports
  ### results in a Hash
  ### ---------------------------------------------------------------

  def commit?
  end
  
  ### ---------------------------------------------------------------
  ### rollback! - used to rollback the configuration
  ### ---------------------------------------------------------------
  
  def rollback!( rollback_id = 0 )
  end

  ### ---------------------------------------------------------------
  ### config_compare - displays diff (patch format) between
  ### current candidate configuration loaded and the rollback_id
  ### ---------------------------------------------------------------
  
  def config_compare( rollback_id = 0 )
  end
  
end # class Provider    


