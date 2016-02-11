# Syslog Server provider class
#
# Jonathan Tripathy et al., September 2015
#
# Copyright (c) 2014-2016 Cisco and/or its affiliates.
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

require_relative 'node_util'

module Cisco
  # NtpServer - node utility class for NTP Server configuration management
  class SyslogServer < NodeUtil
    attr_reader :name, :level, :vrf

    def initialize(name,
                   level=nil,
                   vrf=nil,
                   instantiate=true)
      fail TypeError unless name.is_a?(String)
      fail TypeError unless name.length > 0
      @name = name

      fail TypeError unless level.is_a?(Integer) || level.nil?
      @level = level

      fail TypeError unless vrf.is_a?(String) || vrf.nil?
      @vrf = vrf

      create if instantiate
    end

    def self.syslogservers
      hash = {}

      syslogservers_list = config_get('syslog_server', 'server')
      return hash if syslogservers_list.nil?

      syslogservers_list.each do |id|
        level = config_get('syslog_server', 'level', id)

        vrf = config_get('syslog_server', 'vrf', id)

        hash[id] = SyslogServer.new(id, level, vrf, false)
      end

      hash
    end

    def ==(other)
      (name == other.name) && (vrf == other.vrf)
    end

    def create
      # Set timestamp units
      config_set('syslog_server',
                 'server',
                 state: '',
                 ip:    "#{name}",
                 level: level.nil? ? '' : "#{level}",
                 vrf:   vrf.nil? ? '' : "use-vrf #{vrf}",
                )
    end

    def destroy
      # Set timestamp units
      config_set('syslog_server',
                 'server',
                 state: 'no',
                 ip:    "#{name}",
                 level: '',
                 vrf:   '',
                )
    end
  end # class
end # module
