module JunosNC; end
  
module JunosNC::Provider    
  
  ## all managed objects have the following properties:
  
  PROPERTIES = [ 
    :exist,           # exists in configuration (or should)
    :active           # active in configuration (or should)
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
  end  
   
end
  
class JunosNC::Provider::Parent
  
  attr_accessor :parent
  attr_accessor :has, :should, :properties
  attr_reader :name
  
  def initialize( p_obj, name = nil, opts = {} )

    @parent = opts[:parent] || nil    
    @ndev = p_obj.instance_variable_get(:@ndev) || p_obj
    @name = name
    @opts = opts
        
    return unless @name       # providers do not have a name
    
    @has = {}         # properties read-from Junos
    @should = {}      # properties to write-back to Junos
  end 

  ### ---------------------------------------------------------------
  ### 'is_provider?' - indicates if this object instance is a 
  ### provider object, rather than a specific instance of the object
  ### ---------------------------------------------------------------  
  
  def is_provider?; @name.nil? end
    
  ### ---------------------------------------------------------------
  ### option controls
  ### ---------------------------------------------------------------  
  
  ## controls the behavior of the "oh_no!" closure for
  ## raising exceptions
  
  def ignore_raise=( value )
    @opts[:ignore_raise] = value
  end  
  
  ### ---------------------------------------------------------------
  ### [] property reader or instance selector
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
  ### 'select' is used to get an item from a Provider
  ### ---------------------------------------------------------------
      
  def select( name )
    raise ArgumentError, "This is not a provider instance" unless is_provider?
    
    this = self.class.new( @ndev, name, @opts )
    this.properties = self.properties
    this.read!    
    this        
  end    

  ### ---------------------------------------------------------------
  ### 'exists?' - does the item exist in the Juos config
  ### ---------------------------------------------------------------
  
  def exists?; @has[:exist]; end  

  ### ---------------------------------------------------------------
  ### 'active?' - is the config item active in the Junos config
  ### ---------------------------------------------------------------    
    
  def active?
    false unless exists?
    @has[:active]
  end
  
  def name_decorated( name = @name )
    self.class.to_s + "['" + name + "']"
  end

  ### ---------------------------------------------------------------
  ### Provider methods to obtain collection information as
  ### 'list' - array of named items
  ### 'catalog' - hash of all items with properties
  ### ---------------------------------------------------------------    
      
  def list!; nil; end
  def catalog!; nil; end

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
    
    oh_no!{ raise ArgumentError, "Not called by provider!" } unless is_provider?
      
    ## if we're here, then we're creating an entirely new
    ## instance of this object.  We should check to see if
    ## it first exists, eh? 
    
    newbie = self.select( name )    
    oh_no!{ raise ArgumentError,  name_decorated(name) + " already exists" if newbie.exists? }
        
    prop_hash.each{ |k,v| newbie[k] = v } unless prop_hash.empty?
    
    ## default mark the newly created object as should exist and should
    ## be active (if not already set)
    
    newbie[:exist] = true
    newbie[:active] ||= true    
    
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
  ## YAML "BIG" in & out methods
  ## ----------------------------------------------------------------  
  ## 'create_big_from_yaml!' is used to create large sections of
  ## provider code, using a YAML file as the definition.  The
  ## YAML file *MUST* have a ':name:' defined, and then any other
  ## data needed by the provider's :xml_big_from_hash method. 
  ## Since not all providers will support this, check first for
  ## the existance of the :xml_big_from_hash method
  ## ----------------------------------------------------------------
    
  def create_big_from_hash!( as_hash, opts = {} )
    write_xml_config! xml_big_from_hash( as_hash, opts )    
  end
  
  def create_big_from_yaml!( filename, opts = {} )
    return nil unless respond_to? :xml_big_from_hash    
    as_hash = YAML.load_file( filename )
    create_big_from_hash!( as_hash, opts )
  end

  def big_to_yaml( filename = nil, opts = {} )  
    return nil unless respond_to? :big_to_hash    
    
    out_hash = big_to_hash( opts )
    out_yaml = out_hash.to_yaml        
    File.open( filename, "w" ){|f| f.puts out_hash.to_yaml } if filename   
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
    rsp = write_xml_config!( xml.doc.root )
    @has[:exist] = false
    rsp
  end

  ### ---------------------------------------------------------------
  ### Junos activation controls
  ### ---------------------------------------------------------------
  
  def activate!
    return nil if @should[:active] == true        
    @should[:active] = true
    write!
  end
  
  def deactivate!
    return nil if @should[:active] == false    
    @should[:active] = false
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
      @has[:exist] = false      
      @has[:active] = true
      init_has
      return nil
    end
    
    ## xml_read_parser *MUST* be implmented by the provider class
    ## it is used to parse the XML into the HASH structure.  It
    ## returns true/false
    
    xml_read_parser( @has_xml, @has )  
  end

  ### ---------------------------------------------------------------
  ### Provider writer methods
  ### ---------------------------------------------------------------
  
  def need_write?; not @should.empty? end
    
  def write!
    return nil if @should.empty?
    
    # create the necessary chagnes and push them to the Junos
    # device.  If an error occurs, it will be raised
    
    xml_change = xml_build_change            
    return nil unless xml_change
    
    rsp = write_xml_config!( xml_change )    
    
    # copy the 'should' values into the 'has' values now that 
    # they've been written back to Junos
        
    @has.merge! @should 
    @should.clear
    
    return rsp
  end       

  ### ---------------------------------------------------------------
  ### XML writer methods
  ### ---------------------------------------------------------------
  
  def xml_at_edit; nil; end
  def xml_at_top; nil; end
  def xml_on_create( xml ); nil; end
  def xml_on_delete( xml ); nil; end
    
  def xml_change_exist( xml )
    return xml_on_create( xml ) if @should[:exist]
    return xml_on_delete( xml )
  end

  ## 'xml_build_change' is used to create the Junos XML
  ## configuration structure.  Generally speaking it 
  ## should not be called by code outside the providers,
  ## but sometimes we might want to, so don't make it private
  
  def xml_build_change( xml_at_here = nil )
    edit_at = xml_at_here || xml_at_edit || xml_at_top    
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
  
  def xml_change_active( xml )
    par = xml.instance_variable_get(:@parent)
    value = @should[:active]  ? 'active' : 'inactive'
    par[value] = value # attribute name is same as value
  end  
  
  ### ---------------------------------------------------------------
  ### 'to_hash' lets us look at the read/write hash structures 
  ### ---------------------------------------------------------------  
  
  def to_hash( which = :read )
    { @name => (which == :read) ? @has : @should }    
  end
  
  ##### !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!  
  ##### !!!!!              PRIVATE METHODS                      !!!!!
  ##### !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!  
  
  private
  
  def set_has_status( xml, has )
    has[:active] = xml['inactive'] ? false : true
    has[:exist] = true
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


