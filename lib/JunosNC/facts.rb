module JunosNC; end

module JunosNC::Facts
  
  class Keeper
    attr_accessor :known
    
    def initialize( ndev )
      @ndev = ndev
      @known = Hash.new
    end
    
    def clear; @known.clear end
    def list; @known.keys end      
    def catalog; @known end      
    
    def uses( *facts )
      values = facts.collect do |f|
        self.send( "fact_read_#{f}", @ndev, @known ) unless @known[f]
        self[f]
      end      
      (values.count == 1) ? values[0] : values      
    end
    
    def self.define( fact, &block )
      define_method( "fact_read_#{fact}".to_sym, block )
    end
  
    def []=(key,value)
      @known[key] = value
    end
    
    def [](key)
      @known[key]
    end
    
    def read!
      fact_readers = self.methods.grep /^fact_read_/
      fact_readers.each do |getter| 
        getter =~ /^fact_read_(\w+)/
        fact = $1.to_sym
        self.send( getter, @ndev, @known ) unless @known[fact]
      end
    end
  
  end # class
end

### -----------------------------------------------------------------
### Module methods for Kernel.extend, to be used by caller and
### other libraries.  DO NOT CHANGE THESE METHOD DEFINITIONS
### -----------------------------------------------------------------

module JunosNC::Facts  
  attr_accessor :providers
  
  def self.Provider( ndev )       
    ndev.providers = []
    factkpr = JunosNC::Facts::Keeper.new( ndev )     
    JunosNC::Provider.attach_instance_variable( ndev, :ndev_facts, factkpr )
    factkpr.read!
  end  
  
  def facts!
    @ndev_facts.clear
    @ndev_facts.read!
  end
  
  def facts
    @ndev_facts
  end
  
  def fact( this_fact )
    @ndev_facts[this_fact]        
  end
  
  def fact_get( fact )
    @ndev_facts[fact]    
  end
  
  def fact_set( fact, rvalue )
    @ndev_facts[fact] = rvalue
  end
    
end; 

### -----------------------------------------------------------------
### Load all of the fact files
### -----------------------------------------------------------------

Dir[File.dirname(__FILE__) + "/facts/*.rb"].each do |file|
  require file
end    





