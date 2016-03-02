# February 2016, Sai Chintalapudi
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
require_relative 'itd_device_group'

module Cisco
  # node_utils class for itd_device_group_node
  class ItdDeviceGroupNode < ItdDeviceGroup
    attr_reader :name

    def initialize(itd_dg_name, node_name, node_type, create=true)
      fail TypeError unless itd_dg_name.is_a?(String)
      fail TypeError unless node_name.is_a?(String)
      fail ArgumentError unless itd_dg_name.length > 0
      fail ArgumentError unless node_name.length > 0

      itd_device_group_name = itd_dg_name
      @itddg = ItdDeviceGroup.itds[itd_device_group_name]
      fail "itd device-group #{itd_device_group_name} does not exist" if
      @itddg.nil?
      @name = node_name
      @node_type = node_type

      set_args_keys_default
      return unless create

      config_set('itd_device_group', 'create_node',
                 name: @itddg.name, ntype: @node_type, nname: @name)
    end

    def self.itd_nodes(node_name=nil)
      fail TypeError unless node_name.is_a?(String) || node_name.nil?
      itd_nodes = {}
      itd_list = ItdDeviceGroup.itds
      return itd_nodes if itd_list.nil?
      itd_list.keys.each do |name|
        match = config_get('itd_device_group',
                           'all_itd_device_group_nodes', name: name)
        next if match.nil?
        match.each do |line|
          local = line.split
          ntype = local[0]
          nname = local[1]
          next unless node_name.nil? || nname == node_name
          hkey = name + '_' + nname
          itd_nodes[hkey] = ItdDeviceGroupNode.new(name, nname, ntype, false)
        end
      end
      itd_nodes
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    def destroy
      config_set('itd_device_group', 'destroy_node', name: @itddg.name,
                ntype: @node_type, nname: @name)
    end

    # Helper method to delete @set_args hash keys
    def set_args_keys_default
      @set_args = { name: @itddg.name }
      @set_args[:ntype] = @node_type
      @set_args[:nname] = @name
      @get_args = @set_args
    end

    def hot_standby
      config_get('itd_device_group', 'hot_standby', @get_args)
    end

    def hot_standby=(state)
      no_cmd = (state ? '' : 'no')
      @set_args[:state] = no_cmd
      config_set('itd_device_group', 'hot_standby', @set_args)
      set_args_keys_default
    end

    def default_hot_standby
      config_get_default('itd_device_group', 'hot_standby')
    end

    def weight
      config_get('itd_device_group', 'weight', @get_args)
    end

    def weight=(val)
      @set_args[:weight] = val
      config_set('itd_device_group', 'weight', @set_args)
      set_args_keys_default
    end

    def default_weight
      config_get_default('itd_device_group', 'weight')
    end
  end  # Class
end    # Module
