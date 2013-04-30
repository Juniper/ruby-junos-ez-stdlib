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

Loads configuration snippets or templates (ERB).  This method does **not** commit the change, only loads the contents into the candidate configuration.  If the load was successful, this method will return `true`. Otherwise it will raise a `Netconf::EditError` exception.

The options Hash enables the following controls:


```
:filename => String
```
Identifies filename on local-system.  File can contain either static config or template in ERB format. The framework will identify the format-style of the content by the filename extension.  You can override this behavior using the `:format` option.  By default, the framework will map extensions to `:format` as follow:

  - `:text` when *.{conf,text,txt}
  - `:set` when *.set
  - `:xml` when *.xml

```
:content => String
```
Ccontent of configuration, rather than loading it from a file.  Handy if you are loading the same content on many devices, and you don't want to keep re-reading it from a file

```
:format => Symbol
```

Identifies the format-style of the configuration.  The default is `:text`.  Setting this option will override the `:filename` extension style mapping.

  `:text` - indcates "text" or "curly-brace" style
  
  `:set` - "set" commands, one per line
  
  `:xml` - native Junos XML
      
```
:binding => Object | Binding
``` 
Required when the configuration content is a Ruby ERB template.  If `:binding` is an Object, then that object becomes the scope of the variables available to the template.  If you want to use the *current scope*, then using the `binding` variable that is availble (it is always there)  

```  
:overwrite!
```
When `true` the provided configuraiton will **COMPLETELY OVERWRITE** any existing configuration.  This is useful when writing an entire configuration from scratch.

```
:replace! 
```
When `true` enables the Junos *replace* option.  This is required if your configuration changes utilize either the `replace:` statement in text-format style or the `replace="replace"` attribute in XML-format style.  You do not need to set this option if you are using the set-format style.

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
