# Syslog Server provider class
#
# June 2018
# Jonathan Tripathy et al., September 2015
#
# Copyright (c) 2014-2018 Cisco and/or its affiliates.
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
require 'resolv'

module Cisco
  # SyslogServer - node utility class for syslog server configuration management
  class SyslogServer < NodeUtil
    attr_reader :name, :level, :port, :vrf, :severity_level, :facility

    LEVEL_TO_NUM = { 'emergencies'   => 0,
                     'alerts'        => 1,
                     'critical'      => 2,
                     'error'         => 3,
                     'warning'       => 4,
                     'notifications' => 5,
                     'info'          => 6,
                     'debugging'     => 7 }.freeze
    NUM_TO_LEVEL = LEVEL_TO_NUM.invert.freeze

    def initialize(opts, instantiate=true)
      @name = opts['name']
      @level = opts['level'] || opts['severity_level']
      @port = opts['port']
      @vrf = opts['vrf']
      @severity_level = opts['severity_level'] || opts['level']
      @facility = opts['facility']

      hostname_regex = /^(?=.{1,255}$)[0-9A-Za-z]
      (?:(?:[0-9A-Za-z]|-){0,61}[0-9A-Za-z])?
      (?:\.[0-9A-Za-z](?:(?:[0-9A-Za-z]|-){0,61}[0-9A-Za-z])?)*\.?$/x

      unless @name =~ Resolv::AddressRegex ||
             @name =~ hostname_regex
        fail ArgumentError,
             "Invalid value '#{@name}' \
        (Must be valid IPv4/IPv6 address or hostname)"
      end

      create if instantiate
    end

    def self.syslogservers
      keys = %w(name level port vrf facility severity_level)
      hash = {}
      syslogservers_list = config_get('syslog_server', 'server')
      return hash if syslogservers_list.nil?

      syslogservers_list.each do |id|
        value_hash = Hash[keys.zip(id)]
        value_hash['severity_level'] = value_hash['level']
        value_hash['vrf'] = 'default' if value_hash['vrf'].nil?
        value_hash['facility'] = 'local7' if value_hash['facility'].nil?
        hash[id[0]] = SyslogServer.new(value_hash, false)
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
                   ip:    @name,
                   level: @level ? "severity #{NUM_TO_LEVEL[@level]}" : '',
                   vrf:   @vrf ? "vrf #{@vrf}" : '',
                  )
      else
        config_set('syslog_server',
                   'server',
                   state:    '',
                   ip:       @name,
                   level:    @level ? "#{@level}" : '',
                   port:     @port ? "port #{@port}" : '',
                   vrf:      @vrf ? "use-vrf #{@vrf}" : '',
                   facility: @facility ? "facility #{@facility}" : '',
                  )
      end
    end

    def destroy(duplicate_vrfs=[])
      if platform == :ios_xr
        if duplicate_vrfs.empty?
          config_set('syslog_server',
                     'server',
                     state: 'no',
                     ip:    @name,
                     level: '',
                     vrf:   @vrf ? "vrf #{@vrf}" : '',
                    )
        else
          warn("#{name} is configured multiple times on the device" \
            ' (possibly in different VRFs). This is unsupported by this' \
            ' API and the duplicate entries are being deleted.')
          duplicate_vrfs.each do |dup|
            config_set('syslog_server',
                       'server',
                       state: 'no',
                       ip:    @name,
                       level: '',
                       vrf:   "vrf #{dup}",
                      )
          end
        end
      else
        config_set('syslog_server',
                   'server',
                   state:    'no',
                   ip:       @name,
                   level:    '',
                   port:     '',
                   vrf:      '',
                   facility: '',
                  )
      end
    end
  end # class
end # module
