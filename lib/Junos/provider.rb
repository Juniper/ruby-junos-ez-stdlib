module Junos; end
  
module Junos::Provider    
  
  PROPERTIES = [:exist, :active]    
      
  def self.attach_instance_variable( on_obj, varsname, new_obj )
    ivar = ("@" + varsname.to_s).to_sym
    on_obj.instance_variable_set( ivar, new_obj )
    on_obj.define_singleton_method( varsname ) do
      on_obj.instance_variable_get( ivar )
    end    
  end  
  
end
  
class Junos::Provider::Parent
  attr_accessor :has, :should, :properties
  attr_reader :name
  
  def initialize( ndev, name = nil, opts = {} )
    @ndev = ndev
    @name = name
    @opts = opts   
    
    return unless @name  
    @has = {}         # properties read-from Junos
    @should = {}      # properties to write-back to Junos
  end 
  
  ### ---------------------------------------------------------------
  ### option controls
  ### ---------------------------------------------------------------  
  
  def ignore_raise=( value )
    @opts[:ignore_raise] = value
  end  
  
  ### ---------------------------------------------------------------
  ### [] is used for two purposes:
  ###
  ###    (1) return an item's property value from the read-from 
  ###        hash (@has), i.e. data from Junos
  ###
  ###    (2) select an item from a Provider, e.g. vlans['Blue']
  ### ---------------------------------------------------------------
   
  def []( property )
    return @has[property] if @has
    self.select( property )    # basically creating a new named object
  end

  ### ---------------------------------------------------------------
  ### 'select' is used to get an item from a Provider
  ### ---------------------------------------------------------------
      
  def select( name )
    this = self.class.new( @ndev, name )
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

  ### ---------------------------------------------------------------
  ### []= is used to store values in the write-back hash (@should)
  ### ---------------------------------------------------------------    
  
  def []=( property, rval )
    raise ArgumentError, "invalid property['#{property.to_s}']" unless properties.include? property
    @should[property] = rval
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
  ### 'create' will build a new object, but does not write the 
  ### contents back to the device.  The caller can chain the
  ### junos_write! method if desired  Alternative, the caller
  ### can use 'create!' which does write to the device.
  ### ---------------------------------------------------------------
  
  def create( name = nil, prop_hash = {}, &block )
        
    ## if we're here, then we're creating an entirely new
    ## instance of this object.  We should check to see if
    ## it first exists, eh?  @@@ TBD
    
    newbie = self.select( name )
    
    oh_no!{ raise ArgumentError,  name_decorated(name) + " already exists" if newbie.exists? }
        
    prop_hash.each{ |k,v| newbie[k] = v } unless prop_hash.empty?
    
    ## if a block is provided, then pass the block the new object
    ## the caller is then expected to set the properies
    
    yield( newbie ) if block_given?
    
    newbie[:exist] = true
    newbie[:active] ||= true
    
    ## return the new object    
    return newbie    
  end
  
  def create!( name = nil, prop_hash = {}, &block )
    newbie = create( name, prop_hash, block )
    write!
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
    rsp = junos_load_xml_config!( xml.doc.root )
    @has[:exist] = false
    rsp
  end
    
  ### ---------------------------------------------------------------
  ### Junos read/write methods
  ### ---------------------------------------------------------------
  
  def read!
    @has.clear
    xml_read!
  end
  
  def need_write?; not @should.empty? end
    
  def write!
    return nil if @should.empty?        
    
    # create the necessary chagnes and push them to the Junos
    # device.  If an error occurs, it will be raised
    
    xml_change = xml_build_change    
    rsp = junos_load_xml_config!( xml_change )    
    
    # copy the 'should' values into the 'has' values now that 
    # they've been written back to Junos
        
    @has.merge! @should 
    @should.clear
    
    return rsp
  end       

  ### ---------------------------------------------------------------
  ### XML read/write methods
  ### ---------------------------------------------------------------
  
  def xml_at_edit; nil; end
  def xml_at_top; nil; end
  def xml_on_create( xml ); nil; end
  def xml_on_delete( xml ); nil; end
    
  def xml_change_exist( xml )
    return xml_on_create( xml ) if @should[:exist]
    return xml_on_delete( xml )
  end
  
  def xml_change_active( xml )
    par = xml.instance_variable_get(:@parent)
    value = @should[:active]  ? 'active' : 'inactive'
    par[value] = value # attribute is same as value
  end
        
  def xml_build_change    
    edit_at = xml_at_edit || xml_at_top
    @should.keys.each do |prop|
      self.send( "xml_change_#{prop}", edit_at )
    end
    edit_at.doc.root    
  end

  ### ---------------------------------------------------------------
  ### YAML
  ### ---------------------------------------------------------------  
  
  def to_hash( which = :read )
    stuff = (which == :read) ? @has : @should    
    { @name => stuff }    
  end
  
  def to_yaml( which = :read )
    to_hash.to_yaml which
  end  
  
  def loadyaml( filename, opts_hash = {} )
    contents = YAML.load_file( filename )
    contents.collect do |name, properties|
      create( name, properties )
    end
  end
  
  ##### !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!  
  ##### !!!!!              PRIVATE METHODS                      !!!!!
  ##### !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!  
  
  private
        
  def status_from_junos( xml, has )
    has[:active] = xml['inactive'] ? false : true
    has[:exist] = true
  end
  
  ### ---------------------------------------------------------------
  ### write configuration to Junos.  Check for errors vs. warnings.
  ### if there are warnings then return the result.  If there are
  ### errors, re-throw the exception object.  If everything was
  ### OK, simply return the result
  ### ---------------------------------------------------------------    
 
  def junos_load_xml_config!( xml )
    begin
      result = @ndev.rpc.load_configuration( xml )
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
  
end    


