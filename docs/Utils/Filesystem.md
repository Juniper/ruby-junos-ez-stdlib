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
Returns the String contents of a file.  If the file does not exist, an `IOError` with String error message is raised.
```ruby
puts ndev.fs.cat '/var/log/messages'
->
May  2 18:05:32 firefly newsyslog[1845]: logfile turned over due to -F request

puts ndev.fs.cat 'foober'
exception->
IOError: "could not resolve file: foober"
```

## `checksum( method, path )` <a name="checksum">
Returns the checksum of a file (MD5, SHA1, SHA256 options) located on the Junos target.  The `method` idetifies the checksum method, and is one of `[:md5, :sha256, :sha1]`.  The `path` argument specifies the file to run the checksum over.  If the `path` file does not exist, then an `IOError` exception with String error-message will be raised.

The following runs an MD5 checksum over the file /var/tmp/junos-vsrx-domestic.tgz located on the Junos target:
```ruby
ndev.fs.checksum :md5, "/var/tmp/junos-vsrx-domestic.tgz"
-> 
"91132caf6030fa88a31c2b9db60ea54d"

# try to get a checksum on a non-existant file ...

ndev.fs.checksum :md5, "foober"
exception->
IOError: "md5: /cf/var/home/jeremy/foober: No such file or directory"
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
Copies a file relative on the Junos filesystem.  Returns `true` if the operations was successful, raises an `IOError` exceptions with error-message otherwise.

```ruby
# copy the vsrx.conf file from the temp directory to the current working directory
ndev.fs.cp! "/var/tmp/vsrx.conf","."
-> 
true

# try to copy a file that doesn't exist
ndev.fs.cp! "/var/tmp/vsrx.conf-bleck","."
(exception)->
IOError: "File does not exist: /var/tmp/vsrx.conf-bleck
File fetch failed"
```

## `cwd( directory )` <a name="cwd">
Changes the current working directory (String)

## `pwd` 
Returns a String of the current working directory

# `df( opts = {} )` <a name="df"> 
"show system storage"

## `ls( *args )` <a name="ls">
Returns a directory/file listing in a Hash structure.  Each primary key is the name of the directory.  If the required path is a file, then the key will be an empty string.
The `*args` determine what information is returned.  The general format of use is:
```
ls <path>, <options>
```
Where `path` is a filesystem-path and `options` is a Hash of controls.  The following options are supported:
```
:format => [:text, :xml, :hash]
```
Determines what format this method returns.  By default this will be `:hash`.  The `:xml` option will return the Junos XML result.  The `:text` option will return the CLI text output.
```
:recurse => true
```
When this option is set, a complete recursive listing will be performed.  This is only valid if the `path` is a directory.  This option will return full informational detail on the files/directories as well.
```
:detail => true
```
When this option is set then detailed information, like file size, is provided. 

If no `*args` are passed, then the file listing of the current working directory is provided:
```ruby
ndev.fs.ls
-> 
{"/cf/var/home/jeremy/"=>
  {:fileblocks=>7370,
   :files=>
    {"FF-no-security.conf"=>{},
     "key1.pub"=>{},
     "vsrx.conf"=>{}},
   :dirs=>{".ssh"=>{}}}}

```
Or if you want the details for the current directory listing
```ruby
[23] pry(main)> ndev.fs.ls :detail=>true
=> {"/cf/var/home/jeremy/"=>
  {:fileblocks=>7370,
   :files=>
    {"FF-no-security.conf"=>
      {:owner=>"jeremy",
       :group=>"staff",
       :links=>1,
       :size=>366682,
       :permissions_text=>"-rw-r--r--",
       :permissions=>644,
       :date=>"Apr 13 21:56",
       :date_epoc=>1365890165},
     "key1.pub"=>
      {:owner=>"jeremy",
       :group=>"staff",
       :links=>1,
       :size=>0,
       :permissions_text=>"-rw-r--r--",
       :permissions=>644,
       :date=>"Apr 27 14:59",
       :date_epoc=>1367074764},
     "vsrx.conf"=>
      {:owner=>"jeremy",
       :group=>"staff",
       :links=>1,
       :size=>1559492,
       :permissions_text=>"-rwxr-xr-x",
       :permissions=>755,
       :date=>"Dec 19 16:27",
       :date_epoc=>1355934448}},
   :dirs=>
    {".ssh"=>
      {:owner=>"jeremy",
       :group=>"staff",
       :links=>2,
       :size=>512,
       :permissions_text=>"drwxr-xr-x",
       :permissions=>755,
       :date=>"Apr 3  14:41",
       :date_epoc=>1365000068}}}}
```

## `mv!( from_path, to_path )` <a name="mv"> 
Move / rename file(s).  Returns `true` if the operation was successful, `IOError` exception with String error-message otherwise.
```ruby
# move the file "vsrx.conf" from the current working directory to the temp directory
ndev.fs.mv! "vsrx.conf","/var/tmp"
-> 
true

# Now do it again to generate an error message[26] pry(main)> ndev.fs.mv! "vsrx.conf","/var/tmp"
ndev.fs.mv! "vsrx.conf","/var/tmp"
exception-> 
IOError:
"mv: /cf/var/home/jeremy/vsrx.conf: No such file or directory"
```

## `rm!( path )` <a name="rm"> 
Removes the file(s) identified by `path`.  Returns `true` if the file(s) are removed OK, `IOError` exception with String error-message otherwise.
```ruby
ndev.fs.rm! "/var/tmp/junos-vsrx-domestic.tgz"
-> 
true

# now try to remove the file again to generate an error ..
ndev.fs.rm! "/var/tmp/junos-vsrx-domestic.tgz"
exception->
IOError:
"rm: /var/tmp/junos-vsrx-domestic.tgz: No such file or directory"
```


