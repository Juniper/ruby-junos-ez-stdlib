# `Junos::Ez::FS::Utils`

A collection of methods to access filesystem specific functions and information. These methods return data in 
Hash / Array structures so the information can be programmatically accessible.

# METHODS

  - [`cat`](#cat) - returns the String contents of a file
  - [`checksum`](#checksum) - returns the checksum of a file (MD5, SHA1, SHA256 options)
  - [`cleanup?`](#cleanup_check) - returns a Hash of files that *would be* removed from "request system storage cleanup"
  - [`cleanup!`](#cleanup) - "request system storage cleanup" (!! NO CONFIRM !!)
  - [`cp!`](#cp) - copies a file relative on the device filesystem
  - [`cwd`](#cwd) - changes the current working directory
  - [`pwd`](#pwd) - returns a String of the current working directory
  - [`df`](#df) - "show system storage"
  - [`ls`](#ls) - "file list", i.e. get a file / directory listing, returns a Hash
  - [`mv!`](#mv) - "file move", i.e. move / rename files
  - [`rm!`](#rm) - "file delete", i.e. deletes files

# USAGE
```ruby

# bind :fs to access the file-system utilities

Junos::Ez::FS::Utils( ndev, :fs )

# get a listing of my home directory files:

pp ndev.fs.ls '/var/home/jeremy', :detail => true
->
{"/var/home/jeremy"=>
  {:fileblocks=>11244,
   :files=>
     "key1.pub"=>
      {:owner=>"jeremy",
       :group=>"staff",
       :links=>1,
       :size=>405,
       :permissions_text=>"-rw-r--r--",
       :permissions=>644,
       :date=>"Apr 27 15:00",
       :date_epoc=>1367074832}, 
     "template-policy-options.conf"=>
      {:owner=>"jeremy",
       :group=>"staff",
       :links=>1,
       :size=>4320,
       :permissions_text=>"-rw-r--r--",
       :permissions=>644,
       :date=>"Nov 6   2011",
       :date_epoc=>1320564278}},
   :dirs=>
    {".ssh"=>
      {:owner=>"jeremy",
       :group=>"staff",
       :links=>2,
       :size=>512,
       :permissions_text=>"drwxr-xr-x",
       :permissions=>755,
       :date=>"Apr 27 19:48",
       :date_epoc=>1367092112},
     "bak"=>
      {:owner=>"jeremy",
       :group=>"staff",
       :links=>2,
       :size=>512,
       :permissions_text=>"drwxr-xr-x",
       :permissions=>755,
       :date=>"Apr 16  2010",
       :date_epoc=>1271441068}}}}
```



# GORY DETAILS

## `cat( filename )` <a name="cat"> 
Returns the String contents of a file.
```ruby
puts ndev.fs.cat '/var/log/messages'
->
May  2 18:05:32 firefly newsyslog[1845]: logfile turned over due to -F request
```

## `checksum( method, path )` <a name="checksum">
Returns the checksum of a file (MD5, SHA1, SHA256 options) located on the Junos target.  The `method` idetifies the checksum method, and is one of `[:md5, :sha256, :sha1]`.  The `path` argument specifies the file to run the checksum over. 

The following runs an MD5 checksum over the file /var/tmp/junos-vsrx-domestic.tgz located on the Junos target:
```ruby
ndev.fs.checksum :md5, "/var/tmp/junos-vsrx-domestic.tgz"
-> 
"91132caf6030fa88a31c2b9db60ea54d"
```
  
## `cleanup?` <a name="cleanup_check"> 
Returns a Hash of files that *would be* removed as a result of the command "request system storage cleanup".
```ruby
ndev.fs.cleanup?
-> 
{"/cf/var/crash/flowd_vsrx.log.firefly.0"=>
  {:size_text=>"650B", :size=>650, :date=>"May  3 13:15"},
 "/cf/var/crash/flowd_vsrx.log.firefly.1"=>
  {:size_text=>"650B", :size=>650, :date=>"May  3 13:22"},
 "/cf/var/crash/flowd_vsrx.log.firefly.2"=>
  {:size_text=>"23B", :size=>23, :date=>"May  5 19:20"},
 "/cf/var/crash/flowd_vsrx.log.firefly.3"=>
  {:size_text=>"650B", :size=>650, :date=>"May  5 19:20"},
 "/cf/var/tmp/vpn_tunnel_orig.id"=>
  {:size_text=>"0B", :size=>0, :date=>"May  5 19:20"}}
```

## `cleanup!` <a name="cleanup">
Performs the command "request system storage cleanup" (!! NO CONFIRM !!), and returns a Hash of the files that were removed.
```ruby
ndev.fs.cleanup!
-> 
{"/cf/var/crash/flowd_vsrx.log.firefly.0"=>
  {:size_text=>"650B", :size=>650, :date=>"May  3 13:15"},
 "/cf/var/crash/flowd_vsrx.log.firefly.1"=>
  {:size_text=>"650B", :size=>650, :date=>"May  3 13:22"},
 "/cf/var/crash/flowd_vsrx.log.firefly.2"=>
  {:size_text=>"23B", :size=>23, :date=>"May  5 19:20"},
 "/cf/var/crash/flowd_vsrx.log.firefly.3"=>
  {:size_text=>"650B", :size=>650, :date=>"May  5 19:20"},
 "/cf/var/tmp/vpn_tunnel_orig.id"=>
  {:size_text=>"0B", :size=>0, :date=>"May  5 19:20"}}
```

## `cp!( from_file, to_file )` <a name="cp">
Copies a file relative on the device filesystem

## `cwd( directory )` <a name="cwd">
Changes the current working directory (String)

## `pwd` 
Returns a String of the current working directory

# `df( opts = {} )` <a name="df"> 
"show system storage"

## `ls( *args )` <a name="ls">
"file list", i.e. get a file / directory listing, returns a Hash

## `mv!( fromt_path, to_path )` <a name="mv"> 
"file move", i.e. move / rename files

## `rm!( path )` <a name="rm"> 
Removes the file(s) identified by `path`.  Returns `true` if the file(s) are removed OK, String error-message otherwise.
```ruby
ndev.fs.rm! "/var/tmp/junos-vsrx-domestic.tgz"
-> 
true

# now try to remove the file again to generate an error ..
ndev.fs.rm! "/var/tmp/junos-vsrx-domestic.tgz"
-> 
"\nrm: /var/tmp/junos-vsrx-domestic.tgz: No such file or directory\n"
```


