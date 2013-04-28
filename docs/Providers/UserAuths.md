# Junos::Ez::UserAuths::Provider

Manages user account ssh-keys, RSA or DSA.  

# USAGE

The provider *name* for accessing the provider is a Hash comprised of the following key/value pairs:

  - `:user` - String, user-name
  - `:keytype` - String, one of ['ssh-rsa', 'ssh-dsa']
  - `:publickey` - String, the public key value

```ruby

# bind :auths for managing ssh-keys directly

Junos::Ez::UserAuths::Provider( ndev, :auths )

# setup a name Hash to access this key

key_name = {}
key_name[:user] = "jeremy"
key_name[:keytype] = "ssh-rsa"
key_name[:publickey] = "ssh-rsa gibberishMagicSwingDeadCatoverHeadand_LetMeLoginFoo"

ssh_key = ndev.auths[ key_name ]

puts "Key does not exist" unless ssh_key.exists?
```

Generally speaking, you probably won't be using this provider directly, but rather using a 
`Junos::Ez::Users::Provider` resource and the `load_ssh_key!` method.  This method makes use of the `Junos::Ez::UserAuths::Provider` internally.
