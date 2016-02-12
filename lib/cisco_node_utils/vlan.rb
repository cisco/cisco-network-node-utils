# Jie Yang, November 2014
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
require_relative 'interface'
require_relative 'fabricpath_global'

# Add some Vlan-specific constants to the Cisco namespace
module Cisco
  VLAN_NAME_SIZE = 33

  # Vlan - node utility class for VLAN configuration management
  class Vlan < NodeUtil
    attr_reader :name, :vlan_id

    def initialize(vlan_id, instantiate=true)
      @vlan_id = vlan_id.to_s
      fail ArgumentError,
           'Invalid value(non-numeric Vlan id)' unless @vlan_id[/^\d+$/]

      create if instantiate
    end

    def self.vlans
      hash = {}
      vlan_list = config_get('vlan', 'all_vlans')
      return hash if vlan_list.nil?

      vlan_list.each do |id|
        hash[id] = Vlan.new(id, false)
      end
      hash
    end

    def create
      config_set('vlan', 'create', @vlan_id)
    end

    def destroy
      config_set('vlan', 'destroy', @vlan_id)
    end

    def cli_error_check(result)
      # The NXOS vlan cli does not raise an exception in some conditions and
      # instead just displays a STDOUT error message; thus NXAPI does not detect
      # the failure and we must catch it by inspecting the "body" hash entry
      # returned by NXAPI. This vlan cli behavior is unlikely to change.
      fail result[2]['body'] if
        result[2].is_a?(Hash) &&
        /(ERROR:|Warning:)/.match(result[2]['body'].to_s)

      # Some test environments get result[2] as a string instead of a hash
      fail result[2] if
        result[2].is_a?(String) &&
        /(ERROR:|Warning:)/.match(result[2])
    end

    def fabricpath_feature
      FabricpathGlobal.fabricpath_feature
    end

    def fabricpath_feature_set(fabricpath_set)
      FabricpathGlobal.fabricpath_feature_set(fabricpath_set)
    end

    def mode
      result = config_get('vlan', 'mode', @vlan_id)
      return default_mode if result.nil?
      case result
      when /fabricpath/i
        return 'fabricpath'
      when /ce/i
        return 'ce'
      end
    end

    def mode=(str)
      str = str.to_s
      if str.empty?
        result = config_set('vlan', 'mode', @vlan_id, 'no', '')
      else
        if 'fabricpath' == str
          fabricpath_feature_set(:enabled) unless
            :enabled == fabricpath_feature
        end
        result = config_set('vlan', 'mode', @vlan_id, '', str)
      end
      cli_error_check(result)
    rescue CliError => e
      raise "[vlan #{@vlan_id}] '#{e.command}' : #{e.clierror}"
    end

    def default_mode
      config_get_default('vlan', 'mode')
    end

    def vlan_name
      result = config_get('vlan', 'name', @vlan_id)
      result.nil? ? default_vlan_name : result
    end

    def vlan_name=(str)
      fail TypeError unless str.is_a?(String)
      if str.empty?
        result = config_set('vlan', 'name', @vlan_id, 'no', '')
      else
        result = config_set('vlan', 'name', @vlan_id, '', str)
      end
      cli_error_check(result)
    rescue CliError => e
      raise "[vlan #{@vlan_id}] '#{e.command}' : #{e.clierror}"
    end

    def default_vlan_name
      sprintf('VLAN%04d', @vlan_id)
    end

    def state
      result = config_get('vlan', 'state', @vlan_id)
      case result
      when /act/
        return 'active'
      when /sus/
        return 'suspend'
      end
    end

    def state=(str)
      str = str.to_s
      if str.empty?
        result = config_set('vlan', 'state', @vlan_id, 'no', '')
      else
        result = config_set('vlan', 'state', @vlan_id, '', str)
      end
      cli_error_check(result)
    rescue CliError => e
      raise "[vlan #{@vlan_id}] '#{e.command}' : #{e.clierror}"
    end

    def default_state
      config_get_default('vlan', 'state')
    end

    def shutdown
      result = config_get('vlan', 'shutdown', @vlan_id)
      # Valid result is either: "active"(aka no shutdown) or "shutdown"
      result[/shut/] ? true : false
    end

    def shutdown=(val)
      no_cmd = (val) ? '' : 'no'
      result = config_set('vlan', 'shutdown', @vlan_id, no_cmd)
      cli_error_check(result)
    rescue CliError => e
      raise "[vlan #{@vlan_id}] '#{e.command}' : #{e.clierror}"
    end

    def default_shutdown
      config_get_default('vlan', 'shutdown')
    end

    def add_interface(interface)
      interface.access_vlan = @vlan_id
    end

    def remove_interface(interface)
      interface.access_vlan = interface.default_access_vlan
    end

    def interfaces
      all_interfaces = Interface.interfaces
      interfaces = {}
      all_interfaces.each do |name, i|
        next unless i.switchport_mode == :access
        next unless i.access_vlan == @vlan_id
        interfaces[name] = i
      end
      interfaces
    end

    def mapped_vni
      config_get('vlan', 'mapped_vni', vlan: @vlan_id)
    end

    def mapped_vni=(vni)
      Feature.vn_segment_vlan_based_enable
      # Remove the existing mapping first as cli doesn't support overwriting.
      config_set('vlan', 'mapped_vni', vlan: @vlan_id,
                         state: 'no', vni: vni)
      # Configure the new mapping
      state = vni == default_mapped_vni ? 'no' : ''
      config_set('vlan', 'mapped_vni', vlan: @vlan_id,
                          state: state, vni: vni)
    end

    def default_mapped_vni
      config_get_default('vlan', 'mapped_vni')
    end
  end # class
end # module
