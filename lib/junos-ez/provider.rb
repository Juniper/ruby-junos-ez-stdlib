##### ---------------------------------------------------------------
##### The Junos::Ez::Provider and associated Parent class make up
##### the main 'framework' of the "EZ" library system.  Please 
##### consider your changes carefully as it will have a large
##### scope of impact.  Thank you.
##### ---------------------------------------------------------------

require 'set'

module Junos; end
module Junos::Ez; end
 
require 'junos-ez/exceptions.rb'  
  
module Junos::Ez
  
  VERSION = "0.0.16"
  
  ### ---------------------------------------------------------------
  ### rpc_errors - decodes the XML into an array of error/Hash
  ### @@@ TBD: this should be moved into the 'netconf' gem
  ### ---------------------------------------------------------------
  
  def self.rpc_errors( as_xml )
    errs = as_xml.xpath('//rpc-error')
    return nil if errs.count == 0         # safety check    
    
    retval = []
    errs.each do |err|
       err_h = {}       
       # every error has a severity and message
       err_h[:severity] = err.xpath('error-severity').text.strip
       err_h[:message] = err.xpath('error-message').text.strip
       
       # some have an edit path error
       unless ( err_path = err.xpath('error-path')).empty?
         err_h[:edit_path] = err_path.text.strip 
       end
         
       # some have addition error-info/bad-element ...
       unless ( bad_i = err.xpath('error-info/bad-element')).empty?
         err_h[:bad_identifier] = bad_i.text.strip
       end
       
       retval << err_h
    end
    retval    
  end

end
  
module Junos::Ez::Provider    
  
  ## all managed objects have the following properties:
  
  PROPERTIES = [ 
    :_exist,          # exists in configuration (or should)
    :_active          # active in configuration (or should)
  ]    

  ## 'attach_instance_variable' is the way to dynamically
  ## add an instance variable to the on_obj and "publish"
  ## it in the same way attr_accessor would.
  
  def self.attach_instance_variable( on_obj, varsname, new_obj )
    ivar = ("@" + varsname.to_s).to_sym
    on_obj.instance_variable_set( ivar, new_obj )
    on_obj.define_singleton_method( varsname ) do
      on_obj.instance_variable_get( ivar )
    end    
    on_obj.providers << varsname
  end  
   
end
  
class Junos::Ez::Provider::Parent
  
  attr_reader :ndev, :parent, :name
  attr_accessor :providers
  attr_accessor :has, :should, :properties
  attr_accessor :list, :catalog
  
  # p_obj - the parent object
  # name - the name of the resource, or nil if this is a provider
  # opts - options to the provider/resource.  :parent is reserved  
  
  def initialize( p_obj, name = nil, opts = {} )
    
    @providers = []
    @parent = opts[:parent] || nil    
    @ndev = p_obj.instance_variable_get(:@ndev) || p_obj
    @name = name
    @opts = opts
    
    @list = []                # array list of item names
    @catalog = {}             # hash catalog of named items
        
    return unless @name           
    # resources only from here ...
    @has = {}         # properties read-from Junos
    @should = {}      # properties to write-back to Junos
  end 

  ### ---------------------------------------------------------------
  ### 'is_provider?' - indicates if this object instance is a 
  ### provider object, rather than a specific instance of the object
  ### ---------------------------------------------------------------  
  
  def is_provider?; @name.nil? end

  ### ---------------------------------------------------------------
  ### is_new? - indicates if this is a new resource
  ### ---------------------------------------------------------------  
    
  def is_new?; (@has[:_exist] == false) || false end
      
  ### ---------------------------------------------------------------
  ### [property] resource property reader or 
  ### ["name"] resource selector from provider
  ### ---------------------------------------------------------------
   
  def []( property )
    return self.select( property ) if is_provider?
    
    # if there is already something in the write-back, then use
    # it before using from the read-cache
    
    return @should[property] if @should[property]
    return @has[property] if @has    
  end
  
  ### ---------------------------------------------------------------
  ### []= property writer (@should)
  ### ---------------------------------------------------------------    
  
  def []=( property, rval )
    raise ArgumentError, "This is not a provider instance" if is_provider?
    raise ArgumentError, "Invalid property['#{property.to_s}']" unless properties.include? property
    
    @should[property] = rval
  end  

  ### ---------------------------------------------------------------
  ### 'select' a resource from a provider
  ### ---------------------------------------------------------------
      
  def select( name )
    raise ArgumentError, "This is not a provider instance" unless is_provider?
    this = self.class.new( @ndev, name, @opts )
    this.properties = self.properties
    this.read!    
    this        
  end    

  ### ---------------------------------------------------------------
  ### 'exists?' - does the resource exist in the Juos config
  ### ---------------------------------------------------------------
  
  def exists?; @has[:_exist]; end  

  ### ---------------------------------------------------------------
  ### 'active?' - is the resource config active in Junos
  ### ---------------------------------------------------------------    
    
  def active?
    false unless exists?
    @has[:_active]
  end
  
  ### @@@ helper method, probably needs to go into 'private section
  ### @@@ TBD
  
  def name_decorated( name = @name )
    self.class.to_s + "['" + name + "']"
  end

  ### ---------------------------------------------------------------
  ### Provider methods to obtain collection information as
  ### 'list' - array of named items
  ### 'catalog' - hash of all items with properties
  ### ---------------------------------------------------------------    
     
  def list
    @list.empty? ? list! : @list
  end    
      
  def list!
    @list.clear
    @list = build_list
  end
  
  def catalog
    @catalog.empty? ? catalog! : @catalog
  end
  
  def catalog!
    @catalog.clear
    @catalog = build_catalog
  end
  
  ### ---------------------------------------------------------------
  ### CREATE methods
  ### ---------------------------------------------------------------
  
  ## ----------------------------------------------------------------
  ## 'create' will build a new object, but does not write the 
  ## contents back to the device.  The caller can chain the
  ## write! method if desired  Alternative, the caller
  ## can use 'create!' which does write to the device.
  ## ----------------------------------------------------------------
  
  def create( name = nil, prop_hash = {}, &block )
        
    ## if this is an existing object, then we shouldn't 
    ## allow the caller to create something.
    
    raise ArgumentError, "Not called by provider!" unless is_provider?
      
    ## if we're here, then we're creating an entirely new
    ## instance of this object.  We should check to see if
    ## it first exists, eh?  So allow the caller to specify
    ## if they want an exception if it already exists; overloading
    ## the use of the prop_hash[:_exist], yo!
    
    newbie = self.select( name )    
    if prop_hash[:_exist]
      raise ArgumentError,  name_decorated(name) + " already exists" if newbie.exists? 
    end
        
    prop_hash.each{ |k,v| newbie[k] = v } unless prop_hash.empty?
    
    ## default mark the newly created object as should exist and should
    ## be active (if not already set)
    
    newbie[:_exist] = true
    newbie[:_active] ||= true    
    
    ## if a block is provided, then pass the block the new object
    ## the caller is then expected to set the properies
    
    yield( newbie ) if block_given?   
    
    ## return the new object    
    return newbie    
  end
  
  ## ----------------------------------------------------------------
  ## 'create!' is just a helper to call create and then write
  ## the config assuming create returns ok.
  ## ----------------------------------------------------------------
  
  def create!( name = nil, prop_hash = {}, &block )
    newbie = create( name, prop_hash, block )
    return nil unless newbie
    newbie.write!
    newbie
  end

  ## ----------------------------------------------------------------
  ## YAML / HASH methods
  ## ----------------------------------------------------------------
      
  def create_from_yaml!( opts = {} )
    raise ArgumentError "Missing :filename param" unless opts[:filename]        
    as_hash = YAML.load_file( opts[:filename] )
    write_xml_config! xml_from_h_expanded( as_hash, opts )     
  end
  
  def create_from_hash!( as_hash, opts = {} )
    write_xml_config! xml_from_h_expanded( as_hash, opts )     
  end

  def to_h_expanded( opts = {} ) 
    to_h( opts ) 
  end
    
  def to_yaml( opts = {} ) 
    out_hash = to_h_expanded( opts )
    out_yaml = out_hash.to_yaml        
    File.open( opts[:filename], "w" ){|f| f.puts out_hash.to_yaml } if opts[:filename]   
    out_yaml    
  end  
  
  ### ---------------------------------------------------------------
  ### 'delete!' will cause the item to be removed from the Junos
  ### configuration
  ### ---------------------------------------------------------------
  
  def delete!
    return nil unless exists?    
    xml = xml_at_top
    par = xml.instance_variable_get(:@parent)    
    par['delete'] = 'delete'
    xml_on_delete( xml )
    rsp = write_xml_config!( xml.doc.root )
    @has[:_exist] = false
    true # rsp ... don't return XML, but let's hear from the community...
  end

  ### ---------------------------------------------------------------
  ### Junos activation controls
  ### ---------------------------------------------------------------
  
  def activate!
    return nil if @should[:_active] == true        
    @should[:_active] = true
    write!
  end
  
  def deactivate!
    return nil if @should[:_active] == false    
    @should[:_active] = false
    write!
  end
  
  ### ---------------------------------------------------------------
  ### Junos rename element
  ### ---------------------------------------------------------------
  
  ## by default, simply allow the new name
  def xml_element_newname( new_name); new_name end
    
  def rename!( new_name )
    return nil unless exists?
    
    xml = xml_at_top
    par = xml.instance_variable_get(:@parent)    
    new_ele_name = xml_element_newname( new_name )
    
    return nil unless new_ele_name
    
    par['rename'] = 'rename'
    par['name'] = new_ele_name

    rsp = write_xml_config!( xml.doc.root )
    @name = new_name
    rsp        
  end
  
  ### ---------------------------------------------------------------
  ### Junos reorder method
  ###
  ### opts[:before] = item-name,
  ### opts[:after] = item-name  
  ### ---------------------------------------------------------------  
    
  def reorder!( opts )
    return nil unless exists?
    
    ## validate opts hash
    ctrl, name = opts.first
    raise ArgumentError, "Invalid operation #{ctrl}" unless [:before,:after].include? ctrl
    
    xml = xml_at_top
    par = xml.instance_variable_get(:@parent)
    par['insert'] = ctrl.to_s
    par['name'] = name
    rsp = write_xml_config! ( xml.doc.root )
    
    return rsp    
  end
  
  ### ---------------------------------------------------------------
  ### Provider each method - this will go and create a managed 
  ### object for each item in the list.  This could get CPU
  ### intensive depending on the number of items under provider
  ### management, yo!
  ### ---------------------------------------------------------------    
  
  def each( &block )
    raise ArgumentError, "not a provider" unless is_provider?
    list.each{ |name| yield select(name ) }
  end
  
  ### ---------------------------------------------------------------
  ### Provider reader methods
  ### ---------------------------------------------------------------    
  
  ## 'init_has' is called when creating a new managed object
  ## or when a caller attempts to retrieve a non-existing one
  
  def init_has; nil end
    
  ## 'xml_get_has_xml' - used to retrieve the starting location of the
  ## actual XML data for the managed object (as compared to the top
  ## of the configuration document
  
  def xml_get_has_xml( xml ); nil end
    
  ## 'xml_config_read!' is ued to retrieve the configuration
  ## from the Junos device
  
  def xml_config_read!
    @ndev.rpc.get_configuration( xml_at_top )    
  end  
    
  def read!
    @has.clear    
    cfg_xml = xml_config_read!
    @has_xml = xml_get_has_xml( cfg_xml )
  
    ## if the thing doesn't exist in Junos, then mark the @has
    ## structure accordingly and call the object init_has for
    ## any defaults
    
    unless @has_xml
      @has[:_exist] ||= false      
      @has[:_active] ||= true
      init_has
      return nil
    end
    
    ## xml_read_parser *MUST* be implmented by the provider class
    ## it is used to parse the XML into the HASH structure.  It
    ## returns true/false
    
    xml_read_parser( @has_xml, @has )  
    
    ## return the Hash representation
    self.has
  end

  ### ---------------------------------------------------------------
  ### Provider writer methods
  ### ---------------------------------------------------------------
  
  def need_write?; not @should.empty? end
    
  def write!
    return nil if @should.empty?
    
    @should[:_exist] ||= true
    
    # create the necessary chagnes and push them to the Junos
    # device.  If an error occurs, it will be raised
    
    xml_change = xml_build_change            
    return nil unless xml_change
    rsp = write_xml_config!( xml_change )    
    
    # copy the 'should' values into the 'has' values now that 
    # they've been written back to Junos
        
    @has.merge! @should 
    @should.clear
    
    # returning 'true' for now.  might need to change this back
    # to 'rsp' depending on the community feedback.  general approach is to not have to 
    # deal with XML, unless it's an exception case.  the only time rsp is really
    # needed is to look at warnings; i.e. not-errors.  errors will generate an exception, yo!
    
    return true
  end       

  ### ---------------------------------------------------------------
  ### XML writer methods
  ### ---------------------------------------------------------------
  
  def xml_at_edit; nil; end
  def xml_at_top; nil; end
  def xml_on_create( xml ); nil; end
  def xml_on_delete( xml ); nil; end
    
  def xml_change__exist( xml )
    return xml_on_create( xml ) if @should[:_exist]    
    
    par = xml.instance_variable_get(:@parent)
    par['delete'] = 'delete'
    
    return xml_on_delete( xml )
  end

  ## 'xml_build_change' is used to create the Junos XML
  ## configuration structure.  Generally speaking it 
  ## should not be called by code outside the providers,
  ## but sometimes we might want to, so don't make it private
  
  def xml_build_change( xml_at_here = nil )
    edit_at = xml_at_here || xml_at_edit || xml_at_top
    
    if @should[:_exist] == false
      xml_change__exist( edit_at )
      return edit_at.doc.root
    end
    
    changed = false
    @should.keys.each do |prop|
      changed = true if self.send( "xml_change_#{prop}", edit_at )
    end 
    (changed) ? edit_at.doc.root : nil
  end
  
  ### ---------------------------------------------------------------
  ### XML common write "change" methods
  ### ---------------------------------------------------------------  
  
  def xml_change_admin( xml )
    xml.disable (@should[:admin] == :up ) ? Netconf::JunosConfig::DELETE : nil
  end  
  
  def xml_change_description( xml )
    xml_set_or_delete( xml, 'description', @should[:description] )
  end    
  
  def xml_change__active( xml )
    par = xml.instance_variable_get(:@parent)
    value = @should[:_active]  ? 'active' : 'inactive'
    par[value] = value # attribute name is same as value
  end  
  
  ### ---------------------------------------------------------------
  ### 'to_h' lets us look at the read/write hash structures 
  ### ---------------------------------------------------------------  
  
  def to_h( which = :read )
    { @name => (which == :read) ? @has : @should }    
  end
  
  ##### !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!  
  ##### !!!!!              PRIVATE METHODS                      !!!!!
  ##### !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!  
  
  private
  
  def set_has_status( xml, has )
    has[:_active] = xml['inactive'] ? false : true
    has[:_exist] = true
  end
  
  ### ---------------------------------------------------------------
  ### write configuration to Junos.  Check for errors vs. warnings.
  ### if there are warnings then return the result.  If there are
  ### errors, re-throw the exception object.  If everything was
  ### OK, simply return the result
  ### ---------------------------------------------------------------    
 
  def write_xml_config!( xml, opts = {} )
    begin
      action = {'action' => 'replace' }
      result = @ndev.rpc.load_configuration( xml, action )
    rescue Netconf::RpcError => e      
      errs = e.rsp.xpath('//rpc-error[error-severity = "error"]')
      raise e unless errs.empty?
      e.rsp
    else
      result
    end
  end
  
  def oh_no!
    return if @opts[:ignore_raise]
    yield if block_given?   # should always be a block given ...
  end

  ### ---------------------------------------------------------------
  ### XML property reader/writer for elements that can be present,
  ### or existing with a "no-" prepended.  For example "retain" or
  ### "no-retain"
  ### ---------------------------------------------------------------  
  
  def xml_read_parse_noele( as_xml, ele_name, as_hash, prop )
    unless (ele = as_xml.xpath("#{ele_name} | no-#{ele_name}")).empty?
      as_hash[prop] = (ele[0].name =~ /^no-/) ? false : true
    end    
  end
  
  def xml_set_or_delete_noele( xml, ele_name, prop = ele_name.to_sym )
    
    # delete what was there
    unless @has[prop].nil?
      value_prop = @has[prop]
      wr_ele_name = value_prop ? ele_name : 'no-' + ele_name
      xml.send(wr_ele_name.to_sym, Netconf::JunosConfig::DELETE)
    end
        
    # if we're not adding anything back, signal that we've done
    # something, and we're done, yo!
    return true if @should[prop].nil?

    # add new value
    value_prop = @should[prop]
    ele_name = 'no-' + ele_name if value_prop == false
    xml.send( ele_name.to_sym )
    
  end
  
  def xml_when_item( xml_item, &block )
    raise ArgumentError, "no block given" unless block_given?
    return unless xml_item[0]
    return yield(xml_item[0]) if block.arity == 1
    yield
  end
  
  ### ---------------------------------------------------------------
  ### XML property writer utilities 
  ### ---------------------------------------------------------------  
  
  def xml_set_or_delete( xml, ele_name, value )
    xml.send( ele_name.to_sym, (value ? value : Netconf::JunosConfig::DELETE) )
  end
  
  def xml_set_or_delete_element( xml, ele_name, should )
    xml.send( ele_name.to_sym, (should) ? nil : Netconf::JunosConfig::DELETE )
  end
  
  def diff_property_array( prop )
    should = @should[prop] || []
    has = @has[prop] || []
    [ should - has,  has - should ]
  end
  
end    


