# December 2015, Sai Chintalapudi
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
require_relative 'interface'

# Add some interface-specific constants to the Cisco namespace
module Cisco
  # InterfacePortChannel - node utility class for port channel config management
  class InterfacePortChannel < NodeUtil
    attr_reader :name

    def initialize(name, instantiate=true)
      fail TypeError unless name.is_a?(String)
      fail ArgumentError unless name.length > 0
      @name = name.downcase
      fail ArgumentError unless @name.start_with?('port-channel')

      create if instantiate
    end

    def self.interfaces
      hash = {}
      intf_list = config_get('interface', 'all_interfaces')
      return hash if intf_list.nil?

      intf_list.each do |id|
        id = id.downcase
        next unless id.start_with?('port-channel')
        hash[id] = InterfacePortChannel.new(id, false)
      end
      hash
    end

    def create
      config_set('interface_portchannel', 'create', @name)
    end

    def destroy
      config_set('interface_portchannel', 'destroy', @name)
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    def lacp_graceful_convergence
      config_get('interface_portchannel', 'lacp_graceful_convergence', @name)
    end

    def lacp_graceful_convergence=(state)
      no_cmd = (state ? '' : 'no')
      config_set('interface_portchannel',
                 'lacp_graceful_convergence', @name, no_cmd)
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def default_lacp_graceful_convergence
      config_get_default('interface_portchannel', 'lacp_graceful_convergence')
    end

    def lacp_max_bundle
      config_get('interface_portchannel', 'lacp_max_bundle', @name)
    end

    def lacp_max_bundle=(val)
      config_set('interface_portchannel', 'lacp_max_bundle', @name, val)
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def default_lacp_max_bundle
      config_get_default('interface_portchannel', 'lacp_max_bundle')
    end

    def lacp_min_links
      config_get('interface_portchannel', 'lacp_min_links', @name)
    end

    def lacp_min_links=(val)
      config_set('interface_portchannel', 'lacp_min_links', @name, val)
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def default_lacp_min_links
      config_get_default('interface_portchannel', 'lacp_min_links')
    end

    def lacp_suspend_individual
      config_get('interface_portchannel', 'lacp_suspend_individual', @name)
    end

    def lacp_suspend_individual=(state)
      no_cmd = (state ? '' : 'no')
      config_set('interface_portchannel',
                 'lacp_suspend_individual', @name, no_cmd)
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def default_lacp_suspend_individual
      config_get_default('interface_portchannel', 'lacp_suspend_individual')
    end

    def port_hash_distribution
      config_get('interface_portchannel', 'port_hash_distribution', @name)
    end

    def port_hash_distribution=(val)
      if val
        state = ''
      else
        state = 'no'
        val = ''
      end
      config_set('interface_portchannel',
                 'port_hash_distribution', @name, state, val)
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def default_port_hash_distribution
      config_get_default('interface_portchannel', 'port_hash_distribution')
    end

    def port_load_defer
      config_get('interface_portchannel', 'port_load_defer', @name)
    end

    def port_load_defer=(state)
      no_cmd = (state ? '' : 'no')
      config_set('interface_portchannel',
                 'port_load_defer', @name, no_cmd)
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def default_port_load_defer
      config_get_default('interface_portchannel', 'port_load_defer')
    end
  end  # Class
end    # Module
