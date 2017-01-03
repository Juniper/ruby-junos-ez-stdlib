require 'junos-ez/provider'

### -----------------------------------------------------------------
### Junos::Ez module devices the toplevel Provider and associated
### Facts class & methods
### -----------------------------------------------------------------

module Junos::Ez

  attr_accessor :providers, :facts

  def self.Provider( ndev )
    ndev.extend Junos::Ez
    ndev.providers = []
    ndev.facts = Junos::Ez::Facts::Keeper.new( ndev )
    ndev.facts.read!
    true
  end

  def fact( name ); facts[name] end
end;

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

    private

    def examine_model(facts)
      model = facts[:hardwaremodel]
      if model == 'Virtual Chassis'
        re = facts.detect {|k,v| k.match(/^RE\d+/)}
        if re
          re_model = re[1][:model]
          if re_model
            model = re_model.start_with?('RE-') ? re_model[3, re_model.length] : re_model
          end
        end
      end
      model
    end
  end # class
end

### -----------------------------------------------------------------
### Load all of the fact files
### -----------------------------------------------------------------

require 'junos-ez/facts/chassis'
require 'junos-ez/facts/personality'
require 'junos-ez/facts/version'
require 'junos-ez/facts/switch_style'
require 'junos-ez/facts/ifd_style'
