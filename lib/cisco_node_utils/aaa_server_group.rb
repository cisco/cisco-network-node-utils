#
# NXAPI implementation of AaaServerGroup class
#
# April 2015, Alex Hunsberger
#
# Copyright (c) 2015 Cisco and/or its affiliates.
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
  class AaaServerGroup < NodeUtil
    attr_reader :name, :type

    def initialize(name, type=:tacacs, create=true)
      fail TypeError unless type.is_a? Symbol
      fail TypeError unless name.is_a? String
      @name = name
      @type = type
      return unless create
      if type == :tacacs
        TacacsServer.new.enable unless TacacsServer.enabled
        node.config_set('aaa_server_group', 'tacacs_group', '', name)
      # elsif type == :radius ...
      else
        fail ArgumentError, "unsupported type #{type}"
      end
    end

    def destroy
      if @type == :tacacs
        node.config_set('aaa_server_group', 'tacacs_group', 'no', @name)
      else
        fail ArgumentError, "unsupported type #{@type}"
      end
    end

    def servers
      servs = {}
      if @type == :tacacs
        tacservers = node.config_get('aaa_server_group',
                                     'tacacs_servers', @name)
        unless tacservers.nil?
          tacservers.each { |s| servs[s] = TacacsServerHost.new(s, false) }
        end
      else
        fail ArgumentError, "unsupported type #{@type}"
      end
      servs
    end

    def servers=(new_servs)
      fail TypeError unless new_servs.is_a? Array
      # just need the names of the current servers for comparison
      current_servs = servers.keys
      new_servs.each do |s|
        # add any servers not yet configured
        next if current_servs.include? s
        if @type == :tacacs
          node.config_set('aaa_server_group', 'tacacs_server', @name, '', s)
        else
          fail ArgumentError, "unsupported type #{@type}"
        end
      end
      current_servs.each do |s|
        # remove any undesired existing servers
        next if new_servs.include? s
        if @type == :tacacs
          node.config_set('aaa_server_group', 'tacacs_server', @name, 'no', s)
        else
          fail ArgumentError, "unsupported type #{@type}"
        end
      end
    end

    def self.default_servers
      node.config_get_default('aaa_server_group', 'servers')
    end

    # allow optionally filtering on server type
    def self.groups(type=nil)
      fail TypeError unless type.nil? || type.is_a?(Symbol)
      grps = {}
      tacgroups = node.config_get('aaa_server_group', 'tacacs_groups') if
        [nil, :tacacs].include?(type) && TacacsServer.enabled
      unless tacgroups.nil?
        tacgroups.each { |s| grps[s] = AaaServerGroup.new(s, :tacacs, false) }
      end
      grps
    end

    def vrf
      if @type == :tacacs
        # vrf is always present in running config
        v = node.config_get('aaa_server_group', 'tacacs_vrf', @name)
        return v.nil? ? AaaServerGroup.default_vrf : v.first
      else
        fail ArgumentError, "unsupported type #{@type}"
      end
    end

    def vrf=(v)
      fail TypeError unless v.is_a? String
      # vrf = "default" is equivalent to unconfiguring vrf
      if @type == :tacacs
        node.config_set('aaa_server_group', 'tacacs_vrf', @name, '', v)
      else
        fail ArgumentError, "unsupported type #{@type}"
      end
    end

    def self.default_vrf
      node.config_get_default('aaa_server_group', 'vrf')
    end

    def deadtime
      if @type == :tacacs
        d = node.config_get('aaa_server_group', 'tacacs_deadtime', @name)
        return d.nil? ? AaaServerGroup.default_deadtime : d.first.to_i
      else
        fail ArgumentError, "unsupported type #{@type}"
      end
    end

    def deadtime=(t)
      no_cmd = t == AaaServerGroup.default_deadtime ? 'no' : ''
      if @type == :tacacs
        node.config_set('aaa_server_group', 'tacacs_deadtime', @name, no_cmd, t)
      else
        fail ArgumentError, "unsupported type #{@type}"
      end
    end

    def self.default_deadtime
      node.config_get_default('aaa_server_group', 'deadtime')
    end

    def source_interface
      if @type == :tacacs
        i = node.config_get('aaa_server_group',
                            'tacacs_source_interface', @name)
        return i.nil? ? AaaServerGroup.default_source_interface : i.first
      else
        fail ArgumentError, "unsupported type #{@type}"
      end
    end

    def source_interface=(s)
      fail TypeError unless s.is_a? String
      no_cmd = s == AaaServerGroup.default_source_interface ? 'no' : ''
      if @type == :tacacs
        node.config_set('aaa_server_group', 'tacacs_source_interface',
                        @name, no_cmd, s)
      else
        fail ArgumentError, "unsupported type #{@type}"
      end
    end

    def self.default_source_interface
      node.config_get_default('aaa_server_group', 'source_interface')
    end
  end
end
