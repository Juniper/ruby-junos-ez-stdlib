# `Junos::Ez::Config::Utils`

A collection of methods to perform file / template based configuration, and configuration control functions, like "commit", "show | compare", "rollback", etc.  These methods return data in Hash / Array structures so the information can be programmatically accessible.

# METHODS

  - [`lock!`](#lock) - attempt exclusive config, returns true or raises Netconf::LockError
  - [`load!`](#load) - loads configuration snippets or templates (ERB)
  - [`diff?`](#diff) - returns String of "show | compare" as String
  - [`commit?`](#commit_check) - checks the candidate config for validation, returns true or Hash of errors
  - [`commit!`](#commit) - performs commit, returns true or raises Netconf::CommitError 
  - [`unlock!`](#unlock) - releases exclusive lock on config
  - [`rollback!`](#rollback) - performs rollback of config
  - [`get_config`](#get_config) - returns text-format of configuration

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



# GORY DETAILS

## lock! <a name="lock">
Attempt exclusive config, returns `true` if you now have the lock, or raises `Netconf::LockError` exception if the lock is not available

## load!( opts = {} ) <a name="load">

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

## diff? <a name="diff">
Returns String of "show | compare" as String.  If there is no diff, then this method returns `nil`.

## commit? <a name="commit_check">

Checks the candidate config for validation, returns `true` or Array of errors.

The following is an example errors:
```ruby
ndev.cu.commit?
->
[{:severity=>"error",
  :message=>"Referenced filter 'foo' is not defined",
  :edit_path=>"[edit interfaces ge-0/0/8 unit 0 family inet]",
  :bad_identifier=>"filter"},
 {:severity=>"error", :message=>"configuration check-out failed"}]
```

## commit!( opts = {} ) <a name="commit">

Performs commit, returns `true` or raises `Netconf::CommitError`.  Available options are:

    :comment => String
A commit log comment that is available when retrieving the commit log.

    :confirm => Fixnum-Minutes
Identifies a timeout in minutes to automatically rollback the configuration unless you explicitly issue another commit action.  This is very useful if you think your configuration changes may lock you out of the device.

## unlock! <a name="unlock">

Releases exclusive lock on config.  If you do not posses the lock, this method will raise an `Netconf::RpcError` exception.

## rollback!( rollback_id = 0 ) <a name="rollback">

Loads a rollback of config, does not commit.

## get_config( scope = nil ) <a name="get_config">

Returns the text-style format of the request config.  If `scope` is `nil` then the entire configuration is returned.  If the `scope` is invalid (asking for the "foo" stanza for example), then a string with "ERROR!" is returned.  If the requested config is non-existant (asking for non-existant interface), then `nil` is returned.

Successful request:
```ruby
puts ndev.cu.get_config "interfaces ge-0/0/0"
->
unit 0 {
    family inet {
        address 192.168.56.2/24;
    }
}
```

Valid request, but not config:
```ruby
puts ndev.cu.get_config "interfaces ge-0/0/3"
-> 
nil
```

Invalid request:
```ruby
puts ndev.cu.get_config "foober jazzbot"
->
ERROR! syntax error: foober
```
