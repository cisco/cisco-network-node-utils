# Fabricpath Topology provider class
#
# Deepak Cherian, November 2015
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
require_relative 'fabricpath_global'

module Cisco
  # node_utils class for fabricpath_topology
  class FabricpathTopo < NodeUtil
    attr_reader :topo_id

    def initialize(topo_id, instantiate=true)
      @topo_id = topo_id.to_s
      fail ArgumentError, "Invalid value(non-numeric
                          Topo id #{@topo_id})" unless @topo_id[/^\d+$/]

      create if instantiate
    end

    def self.topos
      hash = {}
      fabricpath = config_get('fabricpath', 'feature')
      return hash if (:enabled != fabricpath.first.to_sym)
      topo_list = config_get('fabricpath_topology', 'all_topos')
      return hash if topo_list.nil?

      topo_list.each do |id|
        hash[id] = FabricpathTopo.new(id, false)
      end
      hash
    end

    def create
      fabricpath_feature_set(:enabled) unless (:enabled == fabricpath_feature)
      config_set('fabricpath_topology', 'create',
                 @topo_id) unless @topo_id == '0'
    end

    def cli_error_check(result)
      # The NXOS vlan cli does not raise an exception in some conditions and
      # instead just displays a STDOUT error message; thus NXAPI does not detect
      # the failure and we must catch it by inspecting the "body" hash entry
      # returned by NXAPI. This vlan cli behavior is unlikely to change.
      fail result[2]['body'] unless result[2]['body'].empty?
    end

    def destroy
      config_set('fabricpath_topology', 'destroy', @topo_id)
    end

    def fabricpath_feature
      FabricpathGlobal.fabricpath_feature
    end

    def fabricpath_feature_set(fabricpath_set)
      FabricpathGlobal.fabricpath_feature_set(fabricpath_set)
    end

    def state
      result = config_get('fabricpath_topology', 'state', @topo_id)
      return default_state if result.nil?
      case result.first
      when /Up/
        return 'up'
      when /Down/
        return 'default'
      end
    end

    def default_state
      config_get_default('fabricpath_topology', 'state')
    end

    def member_vlans
      array = config_get('fabricpath_topology', 'member_vlans', @topo_id)
      str = array.first
      return [] if str == '--'
      str.gsub!('-', '..')
      if /,/.match(str)
        str.split(/\s*,\s*/)
      else
        str.lines.to_a
      end
    end

    def member_vlans=(str)
      debug "str is #{str} whose class is #{str.class}"
      str = str.join(',') unless str.empty?
      if str.empty?
        result = config_set('fabricpath_topology', 'member_vlans', @topo_id,
                            'no', '')
      else
        str.gsub!('..', '-')
        result = config_set('fabricpath_topology', 'member_vlans', @topo_id,
                            '', str)
      end
      cli_error_check(result)
    rescue CliError => e
      raise "[topo #{@topo_id}] '#{e.command}' : #{e.clierror}"
    end

    def topo_name
      desc = config_get('fabricpath_topology', 'description', @topo_id)
      return '' if desc.nil?
      desc.shift.strip
    end

    def topo_name=(desc)
      fail TypeError unless desc.is_a?(String)
      if desc.empty?
        config_set('fabricpath_topology', 'description', @topo_id, 'no', '')
      else
        config_set('fabricpath_topology', 'description', @topo_id, '', desc)
      end
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def default_topo_name
      config_get_default('fabricpath_topology', 'description')
    end
  end # class
end # module
