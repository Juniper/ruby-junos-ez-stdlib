# Filesystem Utilities

A collection of methods to access filesystem specific functions and information. These methods return data in 
Hash / Array structures so the information can be programmatically accessible, rather than scraping CLI or navigating
Junos XML.

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

# METHODS

  - `cat` - returns the String contents of a file
  - `checksum` - returns the checksum of a file (MD5, SHA1, SHA256 options)
  - `cleanup?` - returns a Hash of files that *would be* removed from "request system storage cleanup"
  - `cleanup!` - "request system storage cleanup" (!! NO CONFIRM !!)
  - `cp!` - copies a file relative on the device filesystem
  - `cwd` - changes the current working directory
  - `pwd` - returns a String of the current working directory
  - `df` - "show system storage"
  - `ls` - "file list", i.e. get a file / directory listing, returns a Hash
  - `mv!` - "file move", i.e. move / rename files
  - `rm!` - "file delete", i.e. deletes files

## ... more docs comming ...


