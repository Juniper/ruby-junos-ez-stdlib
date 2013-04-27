# Junos::Ez::Users::Provider

Manages the on-target configured users, located under Junos `[edit system login]` stanza. 

If you need to modify the SSH key(s) assocaited with this a user, you need to use
the `Junos::Ez::UserSSHKeys::Provider`.

# PROPERTIES

  - `:class` - String, The user priviledge class (like "read-only", or "super-user")
  - `:uid` - Number, User ID (unix).  If not provided, Junos will auto-create
  - `:fullname` - String, User Full Name
  - `:password` - Junos encrypted password

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
user.password = 
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
