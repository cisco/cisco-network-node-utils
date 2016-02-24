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

    LEVEL_TO_NUM = { 'emergencies'   => 0,
                     'alerts'        => 1,
                     'critical'      => 2,
                     'error'         => 3,
                     'warning'       => 4,
                     'notifications' => 5,
                     'info'          => 6,
                     'debugging'     => 7 }.freeze
    NUM_TO_LEVEL = LEVEL_TO_NUM.invert.freeze

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
        # The YAML regex isn't specific enough for some platforms,
        # so we have to do further checking.
        begin
          IPAddr.new(id)
        rescue
          next
        end

        level = config_get('syslog_server', 'level', id)
        level = level[0] if level.is_a?(Array)
        level = LEVEL_TO_NUM[level] if platform == :ios_xr

        vrf = config_get('syslog_server', 'vrf', id)
        vrf = vrf[0] if vrf.is_a?(Array)

        hash[id] = SyslogServer.new(id, level, vrf, false)
      end

      hash
    end

    def ==(other)
      (name == other.name) && (vrf == other.vrf)
    end

    def create
      if platform == :ios_xr

        # This provider only support a 1-1 mapping between host and VRF.
        # Thus, we must remove the other entries on different VRFs.
        all_vrfs = config_get('syslog_server', 'vrf', name)
        destroy(all_vrfs) if all_vrfs.is_a?(Array) && all_vrfs.count > 1

        config_set('syslog_server',
                   'server',
                   state: '',
                   ip:    "#{name}",
                   level: level.nil? ? '' : "severity #{NUM_TO_LEVEL[level]}",
                   vrf:   vrf.nil? ? '' : "vrf #{vrf}",
                  )
      else
        config_set('syslog_server',
                   'server',
                   state: '',
                   ip:    "#{name}",
                   level: level.nil? ? '' : "#{level}",
                   vrf:   vrf.nil? ? '' : "use-vrf #{vrf}",
                  )
      end
    end

    def destroy(duplicate_vrfs=[])
      if platform == :ios_xr
        if duplicate_vrfs.empty?
          config_set('syslog_server',
                     'server',
                     state: 'no',
                     ip:    "#{name}",
                     level: '',
                     vrf:   vrf.nil? ? '' : "vrf #{vrf}",
                    )
        else
          warn("#{name} is configured multiple times on the device" \
            ' (possibly in different VRFs). This is unsupported by this' \
            ' API and the duplicate entries are being deleted.')
          duplicate_vrfs.each do |dup|
            config_set('syslog_server',
                       'server',
                       state: 'no',
                       ip:    "#{name}",
                       level: '',
                       vrf:   "vrf #{dup}",
                      )
          end
        end
      else
        config_set('syslog_server',
                   'server',
                   state: 'no',
                   ip:    "#{name}",
                   level: '',
                   vrf:   '',
                  )
      end
    end
  end # class
end # module
