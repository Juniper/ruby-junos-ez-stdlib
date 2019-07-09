
require 'junos-ez/provider'             # framework code
require 'junos-ez/facts'                # fact keeper
require 'junos-ez/system'               # various system resources
require 'junos-ez/l1_ports'             # physical ports
require 'junos-ez/vlans'                # vlans
require 'junos-ez/l2_ports'             # switch ports
require 'junos-ez/ip_ports'             # ip ports (v4)
require 'junos-ez/lag_ports'            # Link Aggregation Groups
require 'junos-ez/group'

# -------------------------------------------------------------------
# utility libraries, not providers
# -------------------------------------------------------------------

require 'junos-ez/utils/re'
require 'junos-ez/utils/fs'
require 'junos-ez/utils/config'
