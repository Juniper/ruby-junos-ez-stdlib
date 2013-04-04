
require "JunosNC/provider"

module JunosNC::System
  
  class Provider < JunosNC::Provider::Parent
  end
  
end
  
module JunosNC::System::DomainNameServers
  class Provider < JunosNC::Provider::Parent
  end
end  

module JunosNC::System::Syslog
  class Provider < JunosNC::Provider::Parent
  end
end

module JunosNC::System::NTPserver
  class Provider < JunosNC::Provider::Parent
  end
end

module JunosNC::System::TimeService
  class Provider < JunosNC::Provider::Parent
  end
end


