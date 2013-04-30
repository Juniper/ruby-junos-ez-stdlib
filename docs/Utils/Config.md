# Junos::Ez::Config::Utils

A collection of methods to perform file / template based configuration, and configuration control functions, like "commit", "show | compare", "rollback", etc.

These methods return data in Hash / Array structures so the information can be programmatically accessible, rather than scraping CLI or navigating Junos XML.

# USAGE

```ruby
# bind :cu to give us access to the config utilities
Junos::Ez::Config::Utils( ndev, :cu )

# load a Junos configuration file on our local filesys

ndev.cu.load! :filename => 'basic-setup.conf'

# check to see if these changes will commit ok.  if not, display the errors, rollback the config,
# close the netconf session, and exit the program.

unless (result = ndev.cu.commit?) == true
  puts "There are commit errors, dumping result ..."
  pp result
  ndev.cu.rollback!
  ndev.close
  exit 1
end

# commit the confguration and close the netconf session

ndev.cu.commit!
ndev.close
```

# METHODS

  - `lock!` - attempt exclusive config, returns true or raises Netconf::LockError
  - `load!` - loads configuration snippets or templates (ERB)
  - `diff?` - returns String of "show | compare" as String
  - `commit?` - checks the candidate config for validation, returns true or Hash of errors
  - `commit!` - performs commit, returns true or raises Netconf::CommitError 
  - `unlock!` - releases exclusive lock on config
  - `rollback!` - performs rollback of config

# GORY DETAILS

## lock!
Attempt exclusive config, returns true or raises Netconf::LockError

## load!( opts = {} )
Loads configuration snippets or templates (ERB)

The options Hash enables the following controls:

    :filename => String

Identifies filename on local-system.  File can contain either static config or template in ERB format. The framework will identify the format-style of the content by the filename extension.  You can override this behavior      using the `:format` option.  By default, the framework will map extensions to :format as follow:
  - *.{conf,text,txt} <==> :text
  - *.xml  <==> :xml
  - *.set  <==> :set

```
:content => String
```
Ccontent of configuration, rather than loading it from a file.  Handy if you are loading the same content on many devices, and you don't want to keep re-reading it from a file
      
    :format => symbol
    
Identifies the format-style of the configuration.  The default is :text
    :text - indcates "text" or "curly-brace" style
    :set - "set" commands, one per line
    :xml - native Junos XML
      
    
    
  ###    this will override any auto-format from the :filename
  ###
  ### :binding  - indicates file/content is an ERB
  ###    => <object> - will grab the binding from this object
  ###                  using a bit of meta-programming magic
  ###    => <binding> - will use this binding
  ###
  ### :replace! => true - enables the 'replace' option
  ### :overwrite! => true - enables the 'overwrite' optoin
  ###
  ### --- returns ---
  ###   true if the configuration is loaded OK
  ###   raise Netconf::EditError otherwise
  ### ---------------------------------------------------------------

## diff?
Returns String of "show | compare" as String

## commit?
Checks the candidate config for validation, returns true or Hash of errors

## commit!( opts = {} )

    opts[:

Performs commit, returns true or raises Netconf::CommitError 

## unlock! 
Releases exclusive lock on config

## rollback!( rollback_id = )
Performs rollback of config

... more docs comming soon ...
