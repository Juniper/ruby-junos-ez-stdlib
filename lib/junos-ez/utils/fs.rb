=begin
---------------------------------------------------------------------
FS::Utils is a collection of filesystem utility routines. These do 
not map to configuration resources.  However, the provider framework 
lends itself well in case we need to do something later, yo!

Each of the FS::Util methods will provide back a rubyized structure
by default.  The 'options' hash to each method will allow you to
change the return result in either :text or Junos :xml as well.

The following is a quick list of the filesystem utility methods,
these following the unix naming counterparts (mostly)

  cat - returns the contents of the file (String)
  checksum - returns the checksum of a file
  cleanup? - returns Hash info of files that would be removed by ...
  cleanup! - performs a system storage cleanup
  cp! - local file copy (use 'scp' if you want to copy remote/local)
  cwd - change the working directory (String)
  df - shows the system storage (Hash)
  ls - returns a filesystem listing (Hash)
  mv! - rename/move files (true | String error)
  pwd - return the current working directory (String)
  rm! - remove files (String)
  
---------------------------------------------------------------------
=end

module Junos::Ez::FS  
  def self.Utils( ndev, varsym )            
    newbie = Junos::Ez::FS::Provider.new( ndev )      
    Junos::Ez::Provider.attach_instance_variable( ndev, varsym, newbie )    
  end          
end

### -----------------------------------------------------------------
###                        PUBLIC METHODS
### -----------------------------------------------------------------
### class containing filesystem public utility functions
### these are not in alphabetical order, but I should do that, yo!
### -----------------------------------------------------------------

class Junos::Ez::FS::Provider < Junos::Ez::Provider::Parent
  
  ### -------------------------------------------------------------
  ### cwd - change the current working directory.  This method will
  ### return the String of the new working directory or raise
  ### and IOError exception if the directory is invalid
  ### -------------------------------------------------------------
  
  def cwd( directory )
    begin
      got = @ndev.rpc.set_cli_working_directory( :directory => directory )
    rescue => e
      raise IOError, "invalid directory: #{directory}"
    else
      got.xpath('working-directory').text
    end    
  end
  
  ### -------------------------------------------------------------
  ### pwd - retrieve current working directory, return String
  ### -------------------------------------------------------------
  
  def pwd
    ndev.rpc.command("show cli directory").text.strip
  end
  
  def checksum( method, path )    
    got = case method
    when :md5
      @ndev.rpc.get_checksum_information( :path => path )
    when :sha256
      @ndev.rpc.get_sha256_checksum_information( :path => path )
    when :sha1
      @ndev.rpc.get_sha1_checksum_information( :path => path )
    end    
    
    f_chk = got.xpath('file-checksum')
    if (err = f_chk.xpath('rpc-error/error-message')[0])
      raise IOError, err.text.strip
    end    
    f_chk.xpath('checksum').text.strip    
  end
  
  ### -------------------------------------------------------------    
  ## ls - provides directory listing of files/subdirs.  if 
  ## directory is nil, then the current working directory
  ## is used.  The following options (opts) are supported
  ##
  ## :format => [:text, :xml, :hash], default = :hash
  ## :recurse => true     - recursive listing thru subdirs
  ## :detail => true      - file details, on if :recurse
  ### -------------------------------------------------------------    
  
  def ls( *args )
    
    directory = nil
    opts = {}
    
    case args.count
    when 1
      if args[0].kind_of? Hash
        opts = args[0]
      else
        directory = args[0]
      end
    when 2
      directory = args[0]
      opts = args[1]      
    end
    
    # args are the RPC arguments ...
    args = {}
    args[:path] = directory if directory
    args[:recursive] = true if opts[:recurse]
    args[:detail] = true if opts[:detail]      
    args.delete(:detail) if( args[:detail] and args[:recursive])
    
    # RPC output format, default is XML
    outf = { :format => 'text' } if opts[:format] == :text
    
    got = @ndev.rpc.file_list( args, outf )
    return nil unless got
    
    return got.text if opts[:format] == :text
    return got if opts[:format] == :xml
    
    # if we're here, then we need to conver the output 
    # to a Hash.  Joy!
    
    collect_detail = args[:detail] || args[:recursive]
    
    ls_hash = {}
    got.xpath('directory').each do |dir|
      
      dir_name = dir.xpath('directory-name').text.strip
      dir_hash = {}
      
      dir_hash[:fileblocks] = dir.xpath('total-file-blocks').text.to_i
      files_info = dir.xpath('file-information')
      
      dir_hash[:files] = {}       
      dir_hash[:dirs] = {}        # sub-directories
      
      files_info.each do |file|
        f_name = file.xpath('file-name').text.strip
        f_h = {}                                  
        
        if file.xpath('file-directory')[0]
          dir_hash[:dirs][f_name] = f_h
        else
          dir_hash[:files][f_name] = f_h    
        end
        
        next unless collect_detail
        
        f_h[:owner] = file.xpath('file-owner').text.strip
        f_h[:group] = file.xpath('file-group').text.strip
        f_h[:links] = file.xpath('file-links').text.to_i
        f_h[:size] = file.xpath('file-size').text.to_i
        
        xml_when_item(file.xpath('file-symlink-target')) { |i|
          f_h[:symlink] = i.text.strip
        }
        
        fp = file.xpath('file-permissions')[0]
        f_h[:permissions_text] = fp.attribute('format').value
        f_h[:permissions] = fp.text.to_i
        
        fd = file.xpath('file-date')[0]
        f_h[:date] = fd.attribute('format').value
        f_h[:date_epoc] = fd.text.to_i
        
      end # each directory file
      ls_hash[ dir_name ] = dir_hash        
    end # each directory
    
    return nil if ls_hash.empty?
    ls_hash
  end # method: ls
  

  ### -------------------------------------------------------------
  ### cat - is used to obtain the text contents of the file
  ### -------------------------------------------------------------
  
  def cat( filename )                   
    begin
      @ndev.rpc.file_show( :filename => filename ).text
    rescue => e
      raise IOError, e.rsp.xpath('rpc-error/error-message').text.strip
    end
  end
  

  
  ### -------------------------------------------------------------
  ### df - shows the system storage information
  ###
  ### opts[:format] = [:text, :xml, :hash]
  ###    defaults :hash
  ###
  ### opts[:size_div] = value to device size values, 
  ###    valid only for :format == :hash
  ### -------------------------------------------------------------
  
  def df( opts = {} )
        
    outf = {:format => 'text' } if opts[:format] == :text
    args = { :detail => true } if opts[:size_div]
    
    got = @ndev.rpc.get_system_storage( args, outf )
    
    return got.text if opts[:format] == :text
    return got if opts[:format] == :xml
    
    df_h = {}
    ### need to turn this into a Hash
    got.xpath('filesystem').each do |fs|
      fs_name = fs.xpath('filesystem-name').text.strip
      fs_h = {}
      df_h[fs_name] = fs_h
      
      fs_h[:mounted_on] = fs.xpath('mounted-on').text.strip        
      datum = fs.xpath('total-blocks')
      fs_h[:total_blocks] = datum.text.to_i
      fs_h[:total_size] = datum.attribute('format').value
      
      datum = fs.xpath('used-blocks')
      fs_h[:used_blocks] = datum.text.to_i
      fs_h[:used_size] = datum.attribute('format').value
      fs_h[:used_percent] = fs.xpath('used-percent').text.to_i
      
      datum = fs.xpath('available-blocks')
      fs_h[:avail_blocks] = datum.text.to_i
      fs_h[:avail_size] = datum.attribute('format').value
      if opts[:size_div]
        fs_h[:total_size] = fs_h[:total_size].to_i / opts[:size_div]
        fs_h[:used_size] = fs_h[:used_size].to_i / opts[:size_div]
        fs_h[:avail_size] = fs_h[:avail_size].to_i / opts[:size_div]
      end
    end
    df_h
  end
  
  ### -------------------------------------------------------------
  ### cleanup! will perform the 'request system storage cleanup'
  ### command and remove the files.  If you want to check which
  ### files will be removed, use the cleanup? method first
  ### -------------------------------------------------------------
  
  def cleanup!
    got = @ndev.rpc.request_system_storage_cleanup
    gone_h = {}
    got.xpath('file-list/file').each do |file|
      _cleanup_file_to_h( file, gone_h )
    end
    gone_h
  end
  
  ### -------------------------------------------------------------
  ### 'cleanup?' will return information on files that would be
  ### removed if cleanup! was executed
  ### -------------------------------------------------------------
  
  def cleanup?
    got = @ndev.rpc.request_system_storage_cleanup( :dry_run => true )
    dryrun_h = {}
    got.xpath('file-list/file').each do |file|
      _cleanup_file_to_h( file, dryrun_h )
    end
    dryrun_h    
  end

  ### -------------------------------------------------------------
  ### cp! - copies a file.  The from_file and to_file can be
  ### URL parameters, yo!
  ###
  ### opts[:source_address] will set the source address of the
  ### copy command, useful when URL contain SCP, HTTP
  ### -------------------------------------------------------------
  
  def cp!( from_file, to_file, opts = {} )
    args = { :source => from_file, :destination => to_file }
    args[:source_address] = opts[:source_address] if opts[:source_address]
    
    begin
      got = @ndev.rpc.file_copy( args )
    rescue => e
      raise IOError, e.rsp.xpath('rpc-error/error-message').text.strip
    else
      return true
    end
  end
  
  ### -------------------------------------------------------------
  ### 'mv' - just like unix, moves/renames a file
  ### -------------------------------------------------------------
  
  def mv!( from_path, to_path )
    got = @ndev.rpc.command( "file rename #{from_path} #{to_path}" )
    return true if got.nil?     # got no error
    raise IOError, got.text
  end  
  
  ### -------------------------------------------------------------
  ### rm! - just like unix, removes files
  ### -------------------------------------------------------------
  
  def rm!( path )
    got = @ndev.rpc.file_delete( :path => path )
    return true if got.nil?     # got no error
    # otherwise, there was an error, check output
    raise IOError, got.text
  end
    
  
end # class Provider    

### -----------------------------------------------------------------
###                        PRIVATE METHODS
### -----------------------------------------------------------------
### These are helper/private methods, or methods that are current
### work-in-progress/under-investigation
### -----------------------------------------------------------------

class Junos::Ez::FS::Provider
  private
  
  ### private method used to convert 'cleanup' file XML
  ### to hash structure and bind it to collecting hash
  
  def _cleanup_file_to_h( file, attach_h )
    file_name = file.xpath('file-name').text.strip
    file_h = {}
    data = file.xpath('size')
    file_h[:size_text] = data.attribute('format').value
    file_h[:size] = data.text.to_i
    file_h[:date] = file.xpath('date').text.strip
    attach_h[file_name] = file_h
    file_h    
  end
  
  ##### !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  ##### ... HERE THERE BE MONSTERS ....
  ##### !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  
  ### -------------------------------------------------------------
  ### 'diff' just like unix; patch output
  ### @@@ something is getting messed up in the XML translation
  ### @@@ as control characters like (<,>) are getting munged.
  ### @@@ need to investigate with Nokogiri ....
  ### -------------------------------------------------------------
  
  def diff___( from_file, to_file )
    raise StandardError, "Under investigation"      
    got = @ndev.rpc.file_compare( :from_file => from_file, :to_file => to_file )
  end  
  
  # create a .tar file from the files in the given directory.
  # the filename does not need to include the .tar extension, but
  # if you include it, that's ok.
  # NOTE: cannot specify an arbitrary list of files, per Junos RPC
  
  ### !!!! these are only allowed from the CLI, at least as tested 
  ### !!!! on an vSRX.  Need to check on other platforms, etc.
  
  def tar___( directory, filename )
    raise StandardError, "Under investigation"
    got = @ndev.rpc.file_archive( :destination => filename, :source => directory )
  end
  
  # create a .tgz file from the files in the given directory.
  # the filename does not need to include the .tgz extension, but
  # if you include it, that's ok.
  # NOTE: cannot specify an arbitrary list of files, per Junos RPC
  
  def tgz___(  directory, filename )
    raise StandardError, "Under investigation"      
    got = @ndev.rpc.file_archive( :destination => filename, :source => directory, :compress => true )
  end
  
end

