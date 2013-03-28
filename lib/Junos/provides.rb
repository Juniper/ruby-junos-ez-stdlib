require 'Junos/junosmod'

module Junos::Provides    
  PROPERTIES = [:exist, :active]      
end
  
class Junos::Provides::Parent
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
  
  def exists?; not @has_xml.nil?; end  

  ### ---------------------------------------------------------------
  ### 'active?' - is the config item active in the Junos config
  ### ---------------------------------------------------------------    
    
  def active?; @has[:active]; end

  ### ---------------------------------------------------------------
  ### []= is used to store values in the write-back hash (@should)
  ### ---------------------------------------------------------------    
  
  def []=( property, rval )
    @should[property] = rval
  end
  
  def name_decorated( name = @name )
    self.class.to_s + "['" + name + "']"
  end
  
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
    junos_load_xml_config!( xml.doc.root )
  end
    
  ### ---------------------------------------------------------------
  ### Junos read/write methods
  ### ---------------------------------------------------------------
  
  def read!; nil; end
  
  def write!
    return nil if @should.empty?    
    xml_change = xml_build_change    
    junos_load_xml_config!( xml_change )
  end       

  ### ---------------------------------------------------------------
  ### XML read/write methods
  ### ---------------------------------------------------------------
  
  def xml_at_edit; nil; end
  def xml_at_top; nil; end
    
  def xml_change_active( xml )
    par = xml.instance_variable_get(:@parent)
    value = @should[:active]  ? 'active' : 'inactive'
    par[value] = value # attribute is same as value
  end
        
  def xml_build_change    
    edit_at = xml_at_edit || xml_at_top
    @should.keys.each do |property|
      self.send( "xml_change_#{property}", edit_at )
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
    as_hash.to_yaml which
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
        
  def status_from_junos( xml )
    @has[:active] = xml['inactive'] ? false : true
    @has[:exist] = true
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
      throw e unless errs.empty?
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


