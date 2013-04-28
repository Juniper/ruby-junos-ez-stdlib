# Junos::Ez::Users::Provider

Manages the on-target configured users, located under Junos `[edit system login]` stanza. 

# USAGE

The provider *name* selector is the user-name String.

```ruby

# bind :users to provide access to the local login configuration

Junos::Ez::Users::Provider( ndev, :users )

user = ndev.users["jeremy"]

puts "#{user.name} does not exist!" unless user.exists?
```

# PROPERTIES

  - `:class` - String, The user priviledge class (like "read-only", or "super-user")
  - `:uid` - Number, User ID (unix).  If not provided, Junos will auto-create
  - `:fullname` - String, User Full Name
  - `:password` - Junos encrypted password
  - `:ssh_keys` - SSH keys (READ/ONLY)

If you need to modify the user's ssh-keys, see the `load_ssh_key!` method in the next section.



# RESOURCE METHODS

## password=

Used to set the user password by providing a plain-text value.
```ruby

Junos::Ez::User::Provider( ndev, :users )

pp ndev.users.list
-> 
["goofy", "jeremy"]

user = ndev.users["goofy"]
user.to_h
-> 
{"goofy"=>
  {:_active=>true,
   :_exist=>true,
   :uid=>"3000",
   :class=>"read-only",
   :password=>"XRykM8Grm0R0A"}}

# set the password with plaintext value, then re-read the config from the device
user.password = "n3wpassw0rd"
user.read!

user.to_h
->
{"goofy"=>
  {:_active=>true,
   :_exist=>true,
   :uid=>"3000",
   :class=>"read-only",
   :password=>"W05ckLnjLcPCk"}}
```
## load_ssh_key!( :opts = {} )

    opts[:publickey] - String of public-key
    opts[:filename] - String, filename on server to public-key file

This method will create an ssh-key for the user based on the contents of the provided public key.  The key will be written to the device, but not committed (just like resource write!).  The `Junos::Ez::UserAuths::Provider` resource for this key will be returned.

```ruby
user = ndev.users["jeremy"]
pp user.to_h
->
{"jeremy"=>
  {:_active=>true,
   :_exist=>true,
   :uid=>"2008",
   :class=>"super-user",
   :password=>"$1$JhZms6TE$dXF8P1ey1u3G.5j/V9FBk0"}}

# write the key and then re-load user object
user.load_ssh_key! :filename=>'/home/jschulman/.ssh/keys/key1.pub'
user.read!
pp user.to_h
->
{"jeremy"=>
  {:_active=>true,
   :_exist=>true,
   :uid=>"2008",
   :class=>"super-user",
   :password=>"$1$JhZms6TE$dXF8P1ey1u3G.5j/V9FBk0",
   :ssh_keys=>
    {"ssh-rsa"=>
      ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIpOXEUJFfHstdDjVEaTIf5YkTbUliSel6/dsNe"]}}}
```
## ssh_key( keytype, index = 0 )
    keytype: ['ssh-rsa', 'ssh-dsa']

This method will return a formulate name Hash for the specified key.  This name can then be used in conjunction 
with the `Junos::Ez::UserAuth::Provider` class.

The `index` parameter is used to select a key in the event that there is more than one in use.

```ruby
key_name = user.ssh_key( 'ssh-rsa' )
->
{:user=>"jeremy",
 :keytype=>"ssh-rsa",
 :publickey=>
  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIpOXEUJFfHstdDjVEaTIf5YkTbUliSel6/dsNe"}

# bind :auths as so we can directly access ssh-keys ...
Junos::Ez::UserAuths::Provider( ndev, :auths )

# now delete the key from the user.
ndev.auths[ key_name ].delete!
```
