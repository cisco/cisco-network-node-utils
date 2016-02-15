# Fabricpath Topology provider class
#
# Deepak Cherian, November 2015
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
      feature = config_get('fabricpath', 'feature')
      return hash if feature.nil? || feature.to_sym != :enabled
      topo_list = config_get('fabricpath_topology', 'all_topos')
      return hash if topo_list.nil?

      topo_list.each do |id|
        hash[id] = FabricpathTopo.new(id, false)
      end
      hash
    rescue Cisco::CliError => e
      # cmd will syntax reject when feature is not enabled
      raise unless e.clierror =~ /Syntax error/
      return {}
    end

    def create
      fabricpath_feature_set(:enabled) unless :enabled == fabricpath_feature
      config_set('fabricpath_topology', 'create',
                 topo_id: @topo_id) unless @topo_id == '0'
    end

    def destroy
      config_set('fabricpath_topology', 'destroy', topo_id: @topo_id)
    end

    def fabricpath_feature
      FabricpathGlobal.fabricpath_feature
    end

    def fabricpath_feature_set(fabricpath_set)
      FabricpathGlobal.fabricpath_feature_set(fabricpath_set)
    end

    def member_vlans
      config_get('fabricpath_topology', 'member_vlans',
                 @topo_id).gsub(/\s+/, '')
    end

    def member_vlans=(str)
      if str.empty?
        state = 'no'
        range = ''
      else
        state = ''
        range = str
        # reset existing range since we don't want incremental sets
        config_set('fabricpath_topology', 'member_vlans', topo_id: @topo_id,
                   state: 'no', vlan_range: '') if member_vlans != ''
      end
      config_set('fabricpath_topology', 'member_vlans', topo_id: @topo_id,
                 state: state, vlan_range: range)
    end

    def default_member_vlans
      config_get_default('fabricpath_topology', 'member_vlans')
    end

    def member_vnis
      config_get('fabricpath_topology', 'member_vnis', @topo_id).gsub(/\s+/, '')
    end

    def member_vnis=(str)
      debug "str is #{str} whose class is #{str.class}"
      str = str.join(',') unless str.empty?
      if str.empty?
        state = 'no'
        range = ''
      else
        state = ''
        range = str
      end
      config_set('fabricpath_topology', 'member_vnis', topo_id: @topo_id,
                 state: state, vni_range: range)
    end

    def default_member_vnis
      config_get_default('fabricpath_topology', 'member_vlans')
    end

    def topo_name
      config_get('fabricpath_topology', 'description', @topo_id)
    end

    def topo_name=(desc)
      fail TypeError unless desc.is_a?(String)
      if desc.empty?
        state = 'no'
        name = ''
      else
        state = ''
        name = desc
      end
      config_set('fabricpath_topology', 'description', topo_id: @topo_id,
                 state: state, name: name)
    end

    def default_topo_name
      config_get_default('fabricpath_topology', 'description')
    end
  end # class
end # module
