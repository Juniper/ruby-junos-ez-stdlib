require 'junos-ez/provider'

module Junos::Ez::Facts
  
  class Keeper
    attr_accessor :known
    
    def initialize( ndev )
      @ndev = ndev
      @known = Hash.new
    end
    
    def clear; @known.clear end
      
    def list; @known.keys end   
    def list!; read!; list; end
      
    def catalog; @known end          
    def catalog!; read!; catalog end
          
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
      @known.clear
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

module Junos::Ez::Facts  
  attr_accessor :providers, :facts

  def self.Provider( ndev )       
    ndev.extend Junos::Ez::Facts    
    ndev.providers = []
    ndev.facts = Junos::Ez::Facts::Keeper.new( ndev )     
    ndev.facts.read!
    true
  end      
  
  def fact( name ); facts[name] end

end; 

### -----------------------------------------------------------------
### Load all of the fact files
### -----------------------------------------------------------------

Dir[File.dirname(__FILE__) + "/facts/*.rb"].each do |file|
  require file
end    





