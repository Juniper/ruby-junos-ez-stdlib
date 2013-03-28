module Junos
  
  def self.dynvar( on_obj, varsname, new_obj )
    ivar = ("@" + varsname.to_s).to_sym
    on_obj.instance_variable_set( ivar, new_obj )
    on_obj.define_singleton_method( varsname ) do
      on_obj.instance_variable_get( ivar )
    end
  end
  
  
end

