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

require_relative 'cisco_cmn_utils'
require_relative 'node_util'
require_relative 'interface'
require_relative 'fabricpath_global'
require_relative 'feature'
require_relative 'vlan_DEPRECATED'

# Add some Vlan-specific constants to the Cisco namespace
module Cisco
  VLAN_NAME_SIZE = 33

  # Vlan - node utility class for VLAN configuration management
  class Vlan < Cisco::VlanDeprecated
    attr_reader :vlan_id

    def initialize(vlan_id, instantiate=true)
      @vlan_id = vlan_id.to_s
      fail ArgumentError,
           'Invalid value(non-numeric Vlan id)' unless @vlan_id[/^\d+$/]

      create if instantiate
    end

    def to_s
      "VLAN #{vlan_id}"
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

    def cli_error_check(result, ignore_message=nil)
      # The NXOS vlan cli does not raise an exception in some conditions and
      # instead just displays a STDOUT error message; thus NXAPI does not detect
      # the failure and we must catch it by inspecting the "body" hash entry
      # returned by NXAPI. This vlan cli behavior is unlikely to change.
      # Check for messages that can be safely ignored.

      errors = /(ERROR:|VLAN:|Warning:)/

      return unless
        result[2].is_a?(Hash) && errors.match(result[2]['body'].to_s)
      # Split errors into a list, but keep the delimiter as part of the message.
      error_list =
        (result[2]['body'].split(errors) - ['']).each_slice(2).map(&:join)
      error_list.each do |msg|
        next if ignore_message && msg.to_s.include?(ignore_message)
        fail Cisco::CliError, result[2]['body']
      end
    end

    def set_args_keys_default
      keys = { vlan: @vlan_id }
      @set_args = keys
    end

    def set_args_keys(hash={}) # rubocop:disable Style/AccessorMethodName
      set_args_keys_default
      @set_args = @set_args.merge!(hash) unless hash.empty?
    end

    def fabric_control
      config_get('vlan', 'fabric_control', vlan: @vlan_id)
    end

    def fabric_control=(val)
      no_cmd = (val) ? '' : 'no'
      result = config_set('vlan', 'fabric_control', vlan:  @vlan_id,
                                                    state: no_cmd)
      cli_error_check(result)
    end

    def default_fabric_control
      config_get_default('vlan', 'fabric_control')
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
      # Note: The yaml definition for this property
      # uses 'multiple' as a workaround for a bug
      # in the N7k nxapi code which displays
      # the 'show vlan' output twice.
      result[0].downcase! if result[0][/FABRICPATH/]
      result[0]
    end

    def mode=(str)
      if str == default_mode
        config_set('vlan', 'mode', @vlan_id, 'no', '')
      else
        if 'fabricpath' == str
          fabricpath_feature_set(:enabled) unless
            :enabled == fabricpath_feature
        end
        config_set('vlan', 'mode', @vlan_id, '', str)
      end
    end

    def default_mode
      config_get_default('vlan', 'mode')
    end

    def vlan_name
      config_get('vlan', 'name', vlanid: @vlan_id)
    end

    def vlan_name=(str)
      fail TypeError unless str.is_a?(String)
      if str.empty?
        result = config_set('vlan', 'name', @vlan_id, 'no', '')
      else
        result = config_set('vlan', 'name', @vlan_id, '', str)
      end
      cli_error_check(result)
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
    end

    def default_state
      config_get_default('vlan', 'state')
    end

    def shutdown
      config_get('vlan', 'shutdown', vlanid: @vlan_id)
    end

    def shutdown=(val)
      no_cmd = (val) ? '' : 'no'
      result = config_set('vlan', 'shutdown', @vlan_id, no_cmd)
      cli_error_check(result)
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
        next unless i.access_vlan.to_i == @vlan_id.to_i
        interfaces[name] = i
      end
      interfaces
    end

    def mapped_vni
      config_get('vlan', 'mapped_vni', vlan: @vlan_id)
    end

    def requires_nv_overlay?
      config_get('vlan', 'mapped_vni_requires_nv_overlay')
    end

    def mapped_vni=(vni)
      # Some platforms require feature nv_overlay to be enabled first.
      Feature.nv_overlay_enable if requires_nv_overlay?
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

    def pvlan_type
      return nil unless Feature.private_vlan_enabled?
      config_get('vlan', 'pvlan_type', id: @vlan_id)
    end

    def pvlan_type=(type)
      Feature.private_vlan_enable
      fail TypeError unless type && type.is_a?(String)

      if type == default_pvlan_type
        return if pvlan_type.empty?
        set_args_keys(state: 'no', type: pvlan_type)
        ignore_msg = 'Warning: Private-VLAN CLI removed'
      else
        set_args_keys(state: '', type: type)
        ignore_msg = 'Warning: Private-VLAN CLI entered'
      end
      result = config_set('vlan', 'pvlan_type', @set_args)
      cli_error_check(result, ignore_msg)
    end

    def default_pvlan_type
      config_get_default('vlan', 'pvlan_type')
    end

    def pvlan_association
      return nil unless Feature.private_vlan_enabled?
      range = config_get('vlan', 'pvlan_association', id: @vlan_id)
      Utils.normalize_range_array(range)
    end

    def pvlan_association=(range)
      Feature.private_vlan_enable
      is = Utils.dash_range_to_elements(pvlan_association)
      should = Utils.dash_range_to_elements(range)
      association_delta(is, should)
    end

    def default_private_vlan_association
      config_get_default('vlan', 'pvlan_association')
    end

    # --------------------------
    # association_delta is a helper function for the pvlan_association
    # property. It walks the delta hash and adds/removes each target private
    # vlan.
    def association_delta(is, should)
      delta_hash = Utils.delta_add_remove(should, is)
      Cisco::Logger.debug("association_delta: #{@vlan_id}: #{delta_hash}")
      [:add, :remove].each do |action|
        delta_hash[action].each do |vlans|
          state = (action == :add) ? '' : 'no'
          set_args_keys(state: state, vlans: vlans)
          result = config_set('vlan', 'pvlan_association', @set_args)
          cli_error_check(result)
        end
      end
    end
  end # class
end # module
