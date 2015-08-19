require "junos-ez/provider"

module Junos::Ez::Group

  PROPERTIES = [ 
    :format,     # [:set, :text, :xml]  
    :path,       # Configuration file path
]  
  
  def self.Provider( ndev, varsym )            
    newbie = Junos::Ez::Group::Provider::new( ndev )            
    newbie.properties = Junos::Ez::Provider::PROPERTIES + PROPERTIES
    Junos::Ez::Provider.attach_instance_variable( ndev, varsym, newbie )
  end
  
  class Provider < Junos::Ez::Provider::Parent
    # common parenting goes here ... if we were to
    # subclass the objects ... not doing that now
  end
  
end

class Junos::Ez::Group::Provider 

  ### ---------------------------------------------------------------
  ### XML top placement
  ### ---------------------------------------------------------------
  
  def xml_at_top
    xml = Nokogiri::XML::Builder.new {|xml| xml.configuration {
      xml.groups {
        xml.name @name
        return xml
      }
    }}
  end
  
  ### ---------------------------------------------------------------
  ### XML property readers
  ### ---------------------------------------------------------------  

  def xml_get_has_xml( xml ) 
    xml.xpath('//groups')[0]
  end
  
  def xml_read_parser( as_xml, as_hash )    
    set_has_status( as_xml, as_hash )  
    
    grp = as_xml.xpath('name').text
    as_hash[:name] = grp unless grp.empty?

  end
  

  ### ---------------------------------------------------------------
  ### XML property writers
  ### ---------------------------------------------------------------    
  
  def xml_change_path( xml )
  end
  
  def xml_change_format( xml )
  end
  
  ### ---------------------------------------------------------------
  ### XML on-create
  ### ---------------------------------------------------------------  
  
  def xml_on_create( xml )
  end
  
  ### ---------------------------------------------------------------
  ### XML on-delete
  ### ---------------------------------------------------------------      
  def xml_on_delete( xml )
  end

  def write_xml_config!( xml, opts = {} )
    if (@should[:_exist] == true)
      _load ( xml )
      @should[:format] = 'xml' unless @should[:format]
      begin
        attr = {}
        attr[:action] = 'replace'
        attr[:format] = @should[:format].to_s
        result = @ndev.rpc.load_configuration( @config.to_s, attr  )
      rescue Netconf::RpcError => e      
        errs = e.rsp.xpath('//rpc-error[error-severity = "error"]')
        raise e unless errs.empty?
        e.rsp
      else
        result
      end
    else
      #Junos::Ez::Provider::Parent.instance_method(:write_xml_config!(xml)).bind(self).call
      super(xml) 
    end
    _apply_group
  end
  
 def write!
    return nil if @should.empty?
    
    @should[:_exist] ||= true
    @should[:_active] ||= :true
    # load the conifguration from file and apply under group
    # hirerachy
    rsp = write_xml_config!( xml_at_top.doc.root )    
    
    # copy the 'should' values into the 'has' values now that 
    # they've been written back to Junos
        
    @has.merge! @should 
    @should.clear
    
    return true
  end

end

  
##### ---------------------------------------------------------------
##### Provider collection methods
##### ---------------------------------------------------------------

class Junos::Ez::Group::Provider

  def build_list
    grp_cfgs = @ndev.rpc.get_configuration{|xml| 
      xml.send(:'groups')
    }.xpath('groups/name').collect do |item|
      item.text
    end 
    return grp_cfgs
  end
  
  def build_catalog
    return @catalog if list!.empty?
    list.each do |grp_name|
      @ndev.rpc.get_configuration{ |xml|
        xml.gropus {
            xml.name grp_name
          }
      }.xpath('groups').each do |as_xml|
        @catalog[grp_name] = {}
        xml_read_parser( as_xml, @catalog[grp_name] )
      end
    end    
    @catalog
    end
end

##### ---------------------------------------------------------------
##### _PRIVATE methods
##### ---------------------------------------------------------------

class Junos::Ez::Group::Provider 

  def _load ( xml )
    return @config = nil if ( @should[:_exist] == false )
    admin = '' 
    if @should[:format].to_s == 'set'
      @config =  "\ndelete groups #{@name}\n" +
                   "edit groups #{@name}\n" + 
                    File.read( @should[:path] ) 
      admin = @should[:_active] == :false ? 'deactivate' : 'activate'
      @config += "\nquit\n"
      @config += "\n#{admin} groups #{@name}"

    elsif @should[:format].to_s == 'text'
      admin = @should[:_active] == :false ? 'inactive' : 'active'
      admin += ": " unless admin.empty? 
      @config = "groups {\n#{admin} replace: #{@name} {\n" + 
                File.read( @should[:path] ) + "\n}\n}"

    elsif @should[:format].to_s == 'xml'
      xml.at_xpath('groups') << File.read( @should[:path])
      @config = xml
    end
    return @config
  end
  
  def _apply_group
    cfg = Netconf::JunosConfig.new(:TOP)
    xml = cfg.doc
    Nokogiri::XML::Builder.with( xml.at_xpath( 'configuration' )) do |dot|
      if @config and @should[:_active] == :true  
        dot.send :'apply-groups', @name
      else 
        dot.send :'apply-groups', @name, Netconf::JunosConfig::DELETE
      end
    end
    begin
      attr = {}
      attr[:action] = 'replace'
      attr[:format] = 'xml'
      result = @ndev.rpc.load_configuration( xml, attr  )
    rescue Netconf::RpcError => e      
      errs = e.rsp.xpath('//rpc-error[error-severity = "error"]')
      raise e unless errs.empty?
      e.rsp
    else
      result
    end
  end

end

