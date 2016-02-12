# VRF_AF provider class
#
# January 2016, Chris Van Heuveln
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

require_relative 'cisco_cmn_utils'
require_relative 'node_util'
require_relative 'feature'

module Cisco
  # VrfAF - node utility class for VRF Address-Family configuration
  class VrfAF < NodeUtil
    attr_reader :name

    def initialize(vrf, af, instantiate=true)
      validate_args(vrf, af)
      create if instantiate
    end

    def self.afs
      hash = {}
      vrfs = config_get('vrf', 'all_vrfs')
      vrfs.each do |vrf|
        hash[vrf] = {}
        afs = config_get('vrf', 'all_vrf_afs', vrf: vrf)

        next if afs.nil?
        afs.each do |af|
          hash[vrf][af] = VrfAF.new(vrf, af, false)
        end
      end
      hash
    end

    def create
      config_set('vrf', 'address_family', set_args_keys(state: ''))
    end

    def destroy
      config_set('vrf', 'address_family', set_args_keys(state: 'no'))
    end

    def validate_args(vrf, af)
      fail ArgumentError unless vrf.is_a?(String) && (vrf.length > 0)
      fail ArgumentError, "'af' must be an array specifying afi and safi" unless
        af.is_a?(Array) || af.length == 2
      @vrf = vrf.downcase
      @afi, @safi = af
      set_args_keys_default
    end

    def set_args_keys_default
      keys = { afi: @afi, safi: @safi }
      keys[:vrf] = @vrf unless @vrf == 'default'
      @get_args = @set_args = keys
    end

    def set_args_keys(hash={}) # rubocop:disable Style/AccessorMethodName
      set_args_keys_default
      @set_args = @get_args.merge!(hash) unless hash.empty?
    end

    def route_target_feature_enable
      Feature.bgp_enable
      Feature.nv_overlay_enable
      Feature.nv_overlay_evpn_enable
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    def route_target_both_auto
      config_get('vrf', 'route_target_both_auto', @get_args)
    end

    def route_target_both_auto=(state)
      route_target_feature_enable
      set_args_keys(state: (state ? '' : 'no'))
      config_set('vrf', 'route_target_both_auto', @set_args)
    end

    def default_route_target_both_auto
      config_get_default('vrf', 'route_target_both_auto')
    end

    # --------------------------
    def route_target_both_auto_evpn
      config_get('vrf', 'route_target_both_auto_evpn', @get_args)
    end

    def route_target_both_auto_evpn=(state)
      route_target_feature_enable
      set_args_keys(state: (state ? '' : 'no'))
      config_set('vrf', 'route_target_both_auto_evpn', @set_args)
    end

    def default_route_target_both_auto_evpn
      config_get_default('vrf', 'route_target_both_auto_evpn')
    end

    # --------------------------
    def route_target_export
      cmds = config_get('vrf', 'route_target_export', @get_args)
      cmds.sort
    end

    def route_target_export=(should)
      route_target_delta(should, route_target_export, 'route_target_export')
    end

    def default_route_target_export
      config_get_default('vrf', 'route_target_export')
    end

    # --------------------------
    def route_target_export_evpn
      cmds = config_get('vrf', 'route_target_export_evpn', @get_args)
      cmds.sort
    end

    def route_target_export_evpn=(should)
      route_target_delta(should, route_target_export_evpn,
                         'route_target_export_evpn')
    end

    def default_route_target_export_evpn
      config_get_default('vrf', 'route_target_export_evpn')
    end

    # --------------------------
    def route_target_import
      cmds = config_get('vrf', 'route_target_import', @get_args)
      cmds.sort
    end

    def route_target_import=(should)
      route_target_delta(should, route_target_import, 'route_target_import')
    end

    def default_route_target_import
      config_get_default('vrf', 'route_target_import')
    end

    # --------------------------
    def route_target_import_evpn
      cmds = config_get('vrf', 'route_target_import_evpn', @get_args)
      cmds.sort
    end

    def route_target_import_evpn=(should)
      route_target_delta(should, route_target_import_evpn,
                         'route_target_import_evpn')
    end

    def default_route_target_import_evpn
      config_get_default('vrf', 'route_target_import_evpn')
    end

    # --------------------------
    # route_target_delta is a common helper function for the route_target
    # properties. It walks the delta hash and adds/removes each target cli.
    def route_target_delta(should, is, prop)
      route_target_feature_enable
      delta_hash = Utils.delta_add_remove(should, is)
      return if delta_hash.values.flatten.empty?
      [:add, :remove].each do |action|
        CiscoLogger.debug("#{prop}" \
          "#{@get_args}\n #{action}: #{delta_hash[action]}")
        delta_hash[action].each do |community|
          state = (action == :add) ? '' : 'no'
          set_args_keys(state: state, community: community)
          config_set('vrf', prop, @set_args)
        end
      end
    end
  end # class
end # module
