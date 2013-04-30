=begin
---------------------------------------------------------------------
Config::Utils is a collection of methods used for loading 
configuration files/templates and software images

   commit! - commit configuration
   commit? - see if a candidate config is OK (commit-check)
   diff? - shows the diff of the candidate config w/current | rolback
   load! - load configuration onto device
   lock! - take exclusive lock on config
   unlock! - release exclusive lock on config
   rollback! - perform a config rollback
   
---------------------------------------------------------------------
=end

module Junos::Ez::Config  
  def self.Utils( ndev, varsym )            
    newbie = Junos::Ez::Config::Provider.new( ndev )      
    Junos::Ez::Provider.attach_instance_variable( ndev, varsym, newbie )    
  end          
end

### -----------------------------------------------------------------
###                        PUBLIC METHODS
### -----------------------------------------------------------------
### -----------------------------------------------------------------

class Junos::Ez::Config::Provider < Junos::Ez::Provider::Parent
  
  ### ---------------------------------------------------------------
  ### load! - used to load configuration files / templates.  This
  ###    does not perform a 'commit', just the equivalent of the
  ###    load-configuration RPC
  ###
  ### --- options ---
  ###
  ### :filename => path - indcates the filename of content
  ###    note: filename extension will also define format
  ###    .{conf,text,txt} <==> :text
  ###    .xml  <==> :xml
  ###    .set  <==> :set
  ###
  ### :content => String - string content of data (vs. :filename)
  ###  
  ### :format =>  [:text, :set, :xml], default :text (curly-brace)
  ###    this will override any auto-format from the :filename
  ###
  ### :binding  - indicates file/content is an ERB
  ###    => <object> - will grab the binding from this object
  ###                  using a bit of meta-programming magic
  ###    => <binding> - will use this binding
  ###
  ### :replace! => true - enables the 'replace' option
  ### :overwrite! => true - enables the 'overwrite' optoin
  ###
  ### --- returns ---
  ###   true if the configuration is loaded OK
  ###   raise Netconf::EditError otherwise
  ### ---------------------------------------------------------------
  
  def load!( opts = {} )
    raise ArgumentError unless opts[:content] || opts[:filename]
    
    content = opts[:content] || File.read( opts[:filename] )    
    
    attrs = {}
    attrs[:action] = 'replace' if opts[:replace!]      
    attrs[:action] = 'override' if opts[:override!]       
    
    if opts[:format] 
      attrs[:format] = opts[:format].to_s
    elsif opts[:filename]
      case f_ext = File.extname( opts[:filename] )
      when '.conf','.text','.txt'; attrs[:format] = 'text'
      when '.set'; attrs[:format] = 'set'
      when '.xml'; # default is XML
      else
        raise ArgumentError, "unknown format from extension: #{f_ext}"
      end
    else
      raise ArgumentError "unspecified format"
    end   
        
    if opts[:binding]
      erb = ERB.new( content, nil, '>' )
      case opts[:binding]
      when Binding
        # binding was provided to use
        content = erb.result( opts[:binding] )
      when Object
        obj = opts[:binding]
        def obj.junos_ez_binding; binding end
        content = erb.result( obj.junos_ez_binding )
        class << obj; remove_method :junos_ez_binding end
      end
    end
    
    @ndev.rpc.load_configuration( content, attrs ) 
    true # everthing OK!    
  end
  
  ### ---------------------------------------------------------------
  ### commit! - commits the configuration to the device
  ### 
  ### --- options ---
  ###
  ### :confirm => true | timeout 
  ### :comment => commit log comment
  ###
  ### --- returns ---
  ###    true if commit completed
  ###    raises Netconf::CommitError otherwise
  ### ---------------------------------------------------------------
  
  def commit!( opts = {} )
    
    args = {}
    args[:log] = opts[:comment] if opts[:comment]
    if opts[:confirm] 
      args[:confirmed] = true
      if opts[:confirm] != true
        timeout = Integer( opts[:confirm] ) rescue false
        raise ArgumentError "invalid timeout #{opts[:confirm]}" unless timeout
        args[:confirm_timeout] = timeout
      end
    end
    
    @ndev.rpc.commit_configuration( args )
    true          
  end

  ### ---------------------------------------------------------------
  ### commit? - perform commit configuration check
  ###
  ### --- returns ---
  ###    true if candidate config is OK to commit
  ###    Array of rpc-error data otherwise
  ### ---------------------------------------------------------------

  def commit?        
    begin
      @ndev.rpc.commit_configuration( :check => true ) 
    rescue => e
      return Junos::Ez::rpc_errors( e.rsp )
    end
    true     # commit check OK!
  end
  
  ### ---------------------------------------------------------------
  ### rollback! - used to rollback the configuration
  ### ---------------------------------------------------------------
  
  def rollback!( rollback_id = 0 )    
    raise ArgumentError, "invalid rollback #{rollback_id}" unless ( rollback_id >= 0 and rollback_id <= 50 )    
    @ndev.rpc.load_configuration( :compare=>'rollback', :rollback=> rollback_id.to_s )
    true   # rollback OK!
  end

  ### ---------------------------------------------------------------
  ### diff? - displays diff (patch format) between
  ### current candidate configuration loaded and the rollback_id
  ###
  ### --- returns ---
  ###    nil if no diff
  ###    String of diff output otherwise
  ### ---------------------------------------------------------------
  
  def diff?( rollback_id = 0 )
    raise ArgumentError, "invalid rollback #{rollback_id}" unless ( rollback_id >= 0 and rollback_id <= 50 )    
    got = ndev.rpc.get_configuration( :compare=>'rollback', :rollback=> rollback_id.to_s )
    diff = got.xpath('configuration-output').text
    return nil if diff == "\n"
    diff
  end
  
  ### ---------------------------------------------------------------
  ### lock! - takes an exclusive lock on the candidate config
  ###
  ### --- returns ---
  ###    true if lock acquired
  ###    raise Netconf::LockError otherwise
  ### ---------------------------------------------------------------
  
  def lock!
    @ndev.rpc.lock_configuration
    true
  end

  ### ---------------------------------------------------------------
  ### unlock! - releases exclusive lock on candidate config
  ###
  ### --- returns ---
  ###    true if lock release
  ###    raise Netconf::RpcError otherwise
  ### ---------------------------------------------------------------
  
  def unlock!
    @ndev.rpc.unlock_configuration
    true
  end
  
end # class Provider    


