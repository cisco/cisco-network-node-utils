# Tacacs Server Group provider class

# Jonathan Tripathy et al., October 2015

# Copyright (c) 2014-2015 Cisco and/or its affiliates.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require_relative 'node_util'

module Cisco
  # TacacsServerGroup - node utility class for
  # Raidus Server configuration management
  class TacacsServerGroup < NodeUtil
    attr_reader :name

    def initialize(name, instantiate=true)
      unless name.is_a?(String)
        fail ArgumentError, 'Invalid value (Name is not a String)'
      end

      @name = name

      create if instantiate
    end

    def self.tacacs_server_groups
      hash = {}
      group_list = config_get('tacacs_server_group', 'group')
      return hash if group_list.nil?

      group_list.each do |id|
        hash[id] = TacacsServerGroup.new(id, false)
      end

      hash
    end

    def create
      config_set('tacacs_server_group',
                 'group',
                 state: '',
                 name:  @name)
    end

    def destroy
      config_set('tacacs_server_group',
                 'group',
                 state: 'no',
                 name:  @name)
    end

    def ==(other)
      name == other.name
    end

    def default_servers
      config_get_default('tacacs_server_group', 'servers')
    end

    def servers
      val = config_get('tacacs_server_group', 'servers', @name)
      val = default_servers if val.nil?
      val
    end

    def servers=(val)
      fail ArgumentError, 'Servers must be an array of valid IP addresses' \
        unless val.is_a?(Array)

      current = servers

      # Remove IPs that are no longer required
      current.each do |old_ip|
        next if val.include?(old_ip)
        config_set('tacacs_server_group',
                   'servers',
                   group: @name,
                   state: 'no',
                   ip:    old_ip)
      end

      # Add new IPs that aren't already on the device
      val.each do |new_ip|
        fail ArgumentError, 'Servers must be an array of valid IP addresses' \
          unless new_ip[/^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/]

        next unless current.nil? || !current.include?(new_ip)
        config_set('tacacs_server_group',
                   'servers',
                   group: @name,
                   state: '',
                   ip:    new_ip)
      end
    end
  end # class
end # module
