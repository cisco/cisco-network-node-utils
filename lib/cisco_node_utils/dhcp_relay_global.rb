# September 2016, Sai Chintalapudi
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

require_relative 'node_util'

module Cisco
  # node_utils class for dhcp_relay_global
  class DhcpRelayGlobal < NodeUtil
    attr_reader :name

    def initialize(name)
      fail TypeError unless name.is_a?(String)
      fail ArgumentError unless name == 'default'
      @name = name.downcase

      Feature.dhcp_enable
      set_args_keys_default
    end

    def self.globals
      { 'default' => DhcpRelayGlobal.new('default') }
    end

    # Helper method to delete @set_args hash keys
    def set_args_keys_default
      @set_args = {}
      @get_args = @set_args
    end

    # rubocop:disable Style/AccessorMethodName
    def set_args_keys(hash={})
      set_args_keys_default
      @set_args = @get_args.merge!(hash) unless hash.empty?
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    def information_option
      config_get('dhcp_relay_global', 'information_option')
    end

    def information_option=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state)
      config_set('dhcp_relay_global', 'information_option', @set_args)
    end

    def default_information_option
      config_get_default('dhcp_relay_global', 'information_option')
    end

    def information_option_trust
      config_get('dhcp_relay_global', 'information_option_trust')
    end

    def information_option_trust=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state)
      config_set('dhcp_relay_global', 'information_option_trust', @set_args)
    end

    def default_information_option_trust
      config_get_default('dhcp_relay_global', 'information_option_trust')
    end

    def information_option_vpn
      config_get('dhcp_relay_global', 'information_option_vpn')
    end

    def information_option_vpn=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state)
      config_set('dhcp_relay_global', 'information_option_vpn', @set_args)
    end

    def default_information_option_vpn
      config_get_default('dhcp_relay_global', 'information_option_vpn')
    end

    def information_trust_all
      config_get('dhcp_relay_global', 'information_trust_all')
    end

    def information_trust_all=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state)
      config_set('dhcp_relay_global', 'information_trust_all', @set_args)
    end

    def default_information_trust_all
      config_get_default('dhcp_relay_global', 'information_trust_all')
    end

    def relay
      config_get('dhcp_relay_global', 'relay')
    end

    def relay=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state)
      config_set('dhcp_relay_global', 'relay', @set_args)
    end

    def default_relay
      config_get_default('dhcp_relay_global', 'relay')
    end

    def smart_relay
      config_get('dhcp_relay_global', 'smart_relay')
    end

    def smart_relay=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state)
      config_set('dhcp_relay_global', 'smart_relay', @set_args)
    end

    def default_smart_relay
      config_get_default('dhcp_relay_global', 'smart_relay')
    end

    def src_addr_hsrp
      config_get('dhcp_relay_global', 'src_addr_hsrp')
    end

    def src_addr_hsrp=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state)
      config_set('dhcp_relay_global', 'src_addr_hsrp', @set_args)
    end

    def default_src_addr_hsrp
      config_get_default('dhcp_relay_global', 'src_addr_hsrp')
    end

    def src_intf
      intf = config_get('dhcp_relay_global', 'src_intf')
      # Normalize by downcasing and removing white space
      intf = intf.downcase.delete(' ') if intf
      intf
    end

    def src_intf=(val)
      state = val == default_src_intf ? 'no' : ''
      intf = val == default_src_intf ? '' : val
      set_args_keys(state: state, intf: intf)
      config_set('dhcp_relay_global', 'src_intf', @set_args)
    end

    def default_src_intf
      config_get_default('dhcp_relay_global', 'src_intf')
    end

    def sub_option_circuit_id_custom
      config_get('dhcp_relay_global', 'sub_option_circuit_id_custom')
    end

    def sub_option_circuit_id_custom=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state)
      config_set('dhcp_relay_global', 'sub_option_circuit_id_custom', @set_args)
    end

    def default_sub_option_circuit_id_custom
      config_get_default('dhcp_relay_global', 'sub_option_circuit_id_custom')
    end

    def sub_option_cisco
      config_get('dhcp_relay_global', 'sub_option_cisco')
    end

    def sub_option_cisco=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state)
      config_set('dhcp_relay_global', 'sub_option_cisco', @set_args)
    end

    def default_sub_option_cisco
      config_get_default('dhcp_relay_global', 'sub_option_cisco')
    end

    def v6_option_cisco
      config_get('dhcp_relay_global', 'v6_option_cisco')
    end

    def v6_option_cisco=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state)
      config_set('dhcp_relay_global', 'v6_option_cisco', @set_args)
    end

    def default_v6_option_cisco
      config_get_default('dhcp_relay_global', 'v6_option_cisco')
    end

    def v6_option_vpn
      config_get('dhcp_relay_global', 'v6_option_vpn')
    end

    def v6_option_vpn=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state)
      config_set('dhcp_relay_global', 'v6_option_vpn', @set_args)
    end

    def default_v6_option_vpn
      config_get_default('dhcp_relay_global', 'v6_option_vpn')
    end

    def v6_relay
      config_get('dhcp_relay_global', 'v6_relay')
    end

    def v6_relay=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state)
      config_set('dhcp_relay_global', 'v6_relay', @set_args)
    end

    def default_v6_relay
      config_get_default('dhcp_relay_global', 'v6_relay')
    end

    def v6_src_intf
      intf = config_get('dhcp_relay_global', 'v6_src_intf')
      # Normalize by downcasing and removing white space
      intf = intf.downcase.delete(' ') if intf
      intf
    end

    def v6_src_intf=(val)
      state = val == default_v6_src_intf ? 'no' : ''
      intf = val == default_v6_src_intf ? '' : val
      set_args_keys(state: state, intf: intf)
      config_set('dhcp_relay_global', 'v6_src_intf', @set_args)
    end

    def default_v6_src_intf
      config_get_default('dhcp_relay_global', 'v6_src_intf')
    end
  end # class
end # module
