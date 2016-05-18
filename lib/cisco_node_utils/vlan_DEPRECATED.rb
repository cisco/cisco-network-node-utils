# rubocop: disable Style/FileName
#
# Copyright (c) 2016 Cisco and/or its affiliates.
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
###############################################################################
#
#                        WARNING! WARNING! WARNING!
#
# This file contains deprecated methods that will be removed with version 2.0.0
#
###############################################################################

require_relative 'node_util'
require 'logger'

module Cisco
  # Vlan - node utility class for VLAN configuration management
  class VlanDeprecated < NodeUtil
    def deprecation_warning(method, new_prop=nil)
      if new_prop.nil?
        new_prop = ''
      else
        new_prop = "The new property name is '#{new_prop}'"
      end

      warn "
      #########################################################################
       WARNING: Method '#{method.to_s.delete('=')}'
       is deprecated and should not be used.
       #{new_prop}
      #########################################################################
      "
    end

    def private_vlan_type
      return nil unless Feature.private_vlan_enabled?
      config_get('DEPRECATED', 'private_vlan_type', id: @vlan_id)
    end

    def private_vlan_type=(type)
      deprecation_warning(__method__, 'pvlan_type')
      Feature.private_vlan_enable
      fail TypeError unless type && type.is_a?(String)

      if type == default_private_vlan_type
        return if private_vlan_type.empty?
        set_args_keys(state: 'no', type: private_vlan_type)
        ignore_msg = 'Warning: Private-VLAN CLI removed'
      else
        set_args_keys(state: '', type: type)
        ignore_msg = 'Warning: Private-VLAN CLI entered'
      end
      result = config_set('DEPRECATED', 'private_vlan_type', @set_args)
      cli_error_check(result, ignore_msg)
    end

    def default_private_vlan_type
      config_get_default('DEPRECATED', 'private_vlan_type')
    end

    def private_vlan_association
      return nil unless Feature.private_vlan_enabled?
      range = config_get('DEPRECATED', 'private_vlan_association', id: @vlan_id)
      Utils.normalize_range_array(range)
    end

    def private_vlan_association=(range)
      deprecation_warning(__method__, 'pvlan_association')
      Feature.private_vlan_enable
      is = Utils.dash_range_to_elements(private_vlan_association)
      should = Utils.dash_range_to_elements(range)
      association_delta(is, should)
    end

    def default_private_vlan_association
      config_get_default('DEPRECATED', 'private_vlan_association')
    end

    # --------------------------
    # association_delta is a helper function for the private_vlan_association
    # property. It walks the delta hash and adds/removes each target private
    # vlan.
    def association_delta(is, should)
      delta_hash = Utils.delta_add_remove(should, is)
      Cisco::Logger.debug("association_delta: #{@vlan_id}: #{delta_hash}")
      [:add, :remove].each do |action|
        delta_hash[action].each do |vlans|
          state = (action == :add) ? '' : 'no'
          set_args_keys(state: state, vlans: vlans)
          result = config_set('DEPRECATED',
                              'private_vlan_association', @set_args)
          cli_error_check(result)
        end
      end
    end
  end # Class
end # Module
