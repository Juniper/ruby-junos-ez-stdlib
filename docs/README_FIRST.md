# CODE EXAMPLES

Much of the documentation include small code "snippets".  These are not complete programs, but rather meant to show specific functionality.  

The following libraries are assumed to be in scope:

  - `require 'pp'` : for pretty-printing Ruby objects
  - `require 'pry'` : for setting code break-points

These examples use the `->` symbol to indicate screen output.  For example:

```ruby

port = ndev.l2_ports["ge-0/0/8"]
pp port.to_h
->
{"ge-0/0/0"=>
  {:_active=>true,
   :_exist=>true,
   :description=>"Jeremy port for testing",
   :vlan_tagging=>true,
   :untagged_vlan=>"Green",
   :tagged_vlans=>["Red"]}}

```

Here the Hash structure following the `->` is the output of the prior "pretty-print", `pp port.to_h`, instruction.
