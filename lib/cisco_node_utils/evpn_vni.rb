# December 2015, Andi Shen
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
  # node_utils class for evpn_vni
  class EvpnVni < NodeUtil
    attr_reader :vni

    def initialize(vni, instantiate=true)
      err_msg = "vni must be either a 'String' or an" \
                " 'Integer' object"
      fail ArgumentError, err_msg unless vni.is_a?(Integer) ||
                                         vni.is_a?(String)
      @vni = vni.to_i
      @get_args = @set_args = { vni: @vni }
      create if instantiate
    end

    # Creat a hash of all vni instance
    def self.vnis
      hash = {}
      return hash unless Feature.bgp_enabled?
      vni_list = config_get('evpn_vni', 'vni')
      return hash if vni_list.nil?

      vni_list.each do |vni_id|
        hash[vni_id] = EvpnVni.new(vni_id, false)
      end
      hash
    end

    def create
      EvpnVni.enable unless EvpnVni.enabled
      @set_args[:state] = ''
      config_set('evpn_vni', 'vni', @set_args)
    end

    def destroy
      @set_args[:state] = 'no'
      config_set('evpn_vni', 'vni', @set_args)

      # no evpn if no vni left
      vni_list = config_get('evpn_vni', 'vni')
      config_set('evpn_vni', 'evpn', @set_args) if vni_list.nil?
    end

    # enable feature bgp and nv overlay evpn
    def self.enable
      Feature.bgp_enable
      Feature.nv_overlay_evpn_enable
    end

    def self.enabled
      Feature.bgp_enabled? && Feature.nv_overlay_evpn_enabled?
    end

    def set_args_keys_default
      @set_args = { vni: @vni }
    end

    # Attributes:
    # Route Distinguisher (Getter/Setter/Default)
    def route_distinguisher
      config_get('evpn_vni', 'route_distinguisher', @get_args)
    end

    def route_distinguisher=(rd)
      if rd == default_route_distinguisher
        @set_args[:state] = 'no'
        @set_args[:rd] = ''
      else
        @set_args[:state] = ''
        @set_args[:rd] = rd
      end
      config_set('evpn_vni', 'route_distinguisher', @set_args)
      set_args_keys_default
    end

    def default_route_distinguisher
      config_get_default('evpn_vni', 'route_distinguisher')
    end

    # route target both
    def route_target_both
      cmds = config_get('evpn_vni', 'route_target_both', @get_args)
      cmds.sort
    end

    def route_target_both=(should)
      route_target_delta(should, route_target_both, 'route_target_both')
    end

    def default_route_target_both
      config_get_default('evpn_vni', 'route_target_both')
    end

    # route target export
    def route_target_export
      cmds = config_get('evpn_vni', 'route_target_export', @get_args)
      cmds.sort
    end

    def route_target_export=(should)
      route_target_delta(should, route_target_export, 'route_target_export')
    end

    def default_route_target_export
      config_get_default('evpn_vni', 'route_target_export')
    end

    # route target import
    def route_target_import
      cmds = config_get('evpn_vni', 'route_target_import', @get_args)
      cmds.sort
    end

    def route_target_import=(should)
      route_target_delta(should, route_target_import, 'route_target_import')
    end

    def default_route_target_import
      config_get_default('evpn_vni', 'route_target_import')
    end

    def route_target_delta(should, is, prop)
      delta_hash = Utils.delta_add_remove(should, is)
      return if delta_hash.values.flatten.empty?
      [:add, :remove].each do |action|
        CiscoLogger.debug("#{prop}" \
          "#{@get_args}\n #{action}: #{delta_hash[action]}")
        delta_hash[action].each do |community|
          state = (action == :add) ? '' : 'no'
          @set_args[:state] = state
          @set_args[:community] = community
          config_set('evpn_vni', prop, @set_args)
        end
      end
    end
  end
end
