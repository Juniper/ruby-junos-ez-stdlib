# Configuration Utilities

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

... more docs comming soon ...
