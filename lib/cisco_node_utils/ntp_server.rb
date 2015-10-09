# NTP Server provider class
#
# Jonathan Tripathy et al., September 2015
#
# Copyright (c) 2014-2015 Cisco and/or its affiliates.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require File.join(File.dirname(__FILE__), 'node')
require File.join(File.dirname(__FILE__), 'interface')

module Cisco
  # NtpServer - node utility class for NTP Server configuration management
  class NtpServer < NodeUtil
    def initialize(ntpserver_id, prefer, instantiate=true)
      @ntpserver_id = ntpserver_id.to_s
      @ntpserver_prefer = prefer
      unless @ntpserver_id[/^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/]
        fail ArgumentError, 'Invalid value(IP is not an IP address)'
      end
      unless @ntpserver_prefer == true ||
             @ntpserver_prefer == false ||
             @ntpserver_prefer.nil?
        fail ArgumentError, 'Invalid value(prefer must be true or false)'
      end
      create if instantiate
    end

    def self.ntpservers
      hash = {}
      ntpservers_list = config_get('ntp_server', 'server')
      return hash if ntpservers_list.nil?

      preferred_servers = config_get('ntp_server', 'prefer')
      preferred_servers = [] unless preferred_servers

      ntpservers_list.each do |id|
        hash[id] = NtpServer.new(id, preferred_servers.include?(id), false)
      end

      hash
    end

    def ==(other)
      name == other.name && prefer == other.prefer
    end

    def create
      config_set('ntp_server', 'server', state: '', ip: @ntpserver_id,
                  prefer: @ntpserver_prefer ? 'prefer' : '')
    end

    def destroy
      config_set('ntp_server', 'server',
                 state: 'no', ip: @ntpserver_id, prefer: '')
    end

    def name
      @ntpserver_id
    end

    def prefer
      @ntpserver_prefer
    end
  end # class
end # module
