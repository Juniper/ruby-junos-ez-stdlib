
require 'Junos/junosmod'

### -----------------------------------------------------------------
### Declare the 'namespace' for the Junos::Facts::Keeper class
### -----------------------------------------------------------------

module Junos; module Facts
  class Keeper
    
    attr_accessor :facts
    
    def initialize( ndev )
      @ndev = ndev
      @facts = Hash.new
    end
    
    def uses( *facts )
      values = facts.collect do |f|
        self.send("fact_read_#{f}") unless @facts[f]
        @facts[f]
      end      
      (values.count == 1) ? values[0] : values      
    end
    
    def self.define( fact, &block )
      define_method( "fact_read_#{fact}".to_sym, block )
    end
  
    def []=(key,value)
      @facts[key] = value
    end
    
    def [](key)
      @facts[key]
    end
    
    def read!
      fact_readers = self.methods.grep /^fact_read_/
      fact_readers.each do |getter| 
        getter =~ /^fact_read_(\w+)/
        fact = $1.to_sym
        self.send( getter ) unless @facts[fact]
      end
    end
  
  end # class
end; end

### -----------------------------------------------------------------
### Module methods for Kernel.extend, to be used by caller and
### other libraries.  DO NOT CHANGE THESE METHOD DEFINITIONS
### -----------------------------------------------------------------

module Junos::Facts            
  def facts_create!
    @__Junos_facts__ ||= Keeper.new( self )
    @__Junos_facts__.facts.clear
    @__Junos_facts__.read!
  end
  def facts
    @__Junos_facts__.facts.keys
  end
  def fact_get( fact )
    @__Junos_facts__[fact]    
  end
  def fact_set( fact, rvalue )
    @__Junos_facts__[fact] = rvalue
  end
end; 

### -----------------------------------------------------------------
### Load all of the fact files
### -----------------------------------------------------------------

Dir[File.dirname(__FILE__) + "/facts/*.rb"].each do |file|
  require file
end    





