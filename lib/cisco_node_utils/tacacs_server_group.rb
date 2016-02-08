#
# NXAPI implementation of TacacsServerGroup class
#
# April 2015, Alex Hunsberger
#
# Copyright (c) 2015-2016 Cisco and/or its affiliates.
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
require_relative 'tacacs_server'

module Cisco
  # NXAPI implementation of AAA Server Group class
  class TacacsServerGroup < NodeUtil
    attr_reader :name

    def initialize(name, create=true)
      fail TypeError unless name.is_a? String
      @name = name

      return unless create

      TacacsServer.new.enable unless TacacsServer.enabled
      config_set('tacacs_server_group', 'group', state: '', name: name)
    end

    def destroy
      config_set('tacacs_server_group', 'group', state: 'no', name: @name)
    end

    def servers
      config_get('tacacs_server_group', 'servers', @name)
    end

    def servers=(new_servs)
      fail TypeError unless new_servs.is_a? Array
      current_servs = servers
      new_servs.each do |s|
        # add any servers not yet configured
        next if current_servs.include? s
        config_set('tacacs_server_group',
                   'servers',
                   name:   @name,
                   state:  '',
                   server: s)
      end
      current_servs.each do |s|
        # remove any undesired existing servers
        next if new_servs.include? s
        config_set('tacacs_server_group',
                   'servers',
                   name:   @name,
                   state:  'no',
                   server: s)
      end
    end

    def default_servers
      config_get_default('tacacs_server_group', 'servers')
    end

    def ==(other)
      name == other.name
    end

    # for netdev compatibility
    def self.tacacs_server_groups
      groups
    end

    def self.groups
      grps = {}
      tacgroups = config_get('tacacs_server_group', 'group') if
        TacacsServer.enabled
      unless tacgroups.nil?
        tacgroups.each { |s| grps[s] = TacacsServerGroup.new(s, false) }
      end
      grps
    end

    def vrf
      # vrf is always present in running config
      v = config_get('tacacs_server_group', 'vrf', @name)
      v.nil? ? default_vrf : v
    end

    def vrf=(v)
      fail TypeError unless v.is_a? String
      # vrf = "default" is equivalent to unconfiguring vrf
      config_set('tacacs_server_group', 'vrf', name: @name, state: '', vrf: v)
    end

    def default_vrf
      config_get_default('tacacs_server_group', 'vrf')
    end

    def deadtime
      d = config_get('tacacs_server_group', 'deadtime', @name)
      d.nil? ? default_deadtime : d.to_i
    end

    def deadtime=(t)
      no_cmd = t == default_deadtime ? 'no' : ''
      config_set('tacacs_server_group',
                 'deadtime',
                 name:     @name,
                 state:    no_cmd,
                 deadtime: t)
    end

    def default_deadtime
      config_get_default('tacacs_server_group', 'deadtime')
    end

    def source_interface
      i = config_get('tacacs_server_group', 'source_interface', @name)
      i.nil? ? default_source_interface : i
    end

    def source_interface=(s)
      fail TypeError unless s.is_a? String
      no_cmd = s == default_source_interface ? 'no' : ''
      config_set('tacacs_server_group',
                 'source_interface',
                 name:      @name,
                 state:     no_cmd,
                 interface: s)
    end

    def default_source_interface
      config_get_default('tacacs_server_group', 'source_interface')
    end
  end
end
