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

    def initialize(instantiate=true)
      Feature.dhcp_enable if instantiate
      set_args_keys_default
    end

    def self.globals
      hash = {}
      hash['default'] = DhcpRelayGlobal.new(false) if Feature.dhcp_enabled?
      hash
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

    def destroy
      return unless Feature.dhcp_enabled?
      [:ipv4_information_option,
       :ipv4_information_option_trust,
       :ipv4_information_option_vpn,
       :ipv4_information_trust_all,
       :ipv4_relay,
       :ipv4_smart_relay,
       :ipv4_src_addr_hsrp,
       :ipv4_src_intf,
       :ipv4_sub_option_circuit_id_custom,
       :ipv4_sub_option_circuit_id_string,
       :ipv4_sub_option_cisco,
       :ipv6_option_cisco,
       :ipv6_option_vpn,
       :ipv6_relay,
       :ipv6_src_intf,
      ].each do |prop|
        send("#{prop}=", send("default_#{prop}")) if send prop
      end
      set_args_keys_default
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    def ipv4_information_option
      config_get('dhcp_relay_global', 'ipv4_information_option')
    end

    def ipv4_information_option=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state)
      config_set('dhcp_relay_global', 'ipv4_information_option', @set_args)
    end

    def default_ipv4_information_option
      config_get_default('dhcp_relay_global', 'ipv4_information_option')
    end

    def ipv4_information_option_trust
      config_get('dhcp_relay_global', 'ipv4_information_option_trust')
    end

    def ipv4_information_option_trust=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state)
      config_set('dhcp_relay_global', 'ipv4_information_option_trust',
                 @set_args)
    end

    def default_ipv4_information_option_trust
      config_get_default('dhcp_relay_global', 'ipv4_information_option_trust')
    end

    def ipv4_information_option_vpn
      config_get('dhcp_relay_global', 'ipv4_information_option_vpn')
    end

    def ipv4_information_option_vpn=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state)
      config_set('dhcp_relay_global', 'ipv4_information_option_vpn', @set_args)
    end

    def default_ipv4_information_option_vpn
      config_get_default('dhcp_relay_global', 'ipv4_information_option_vpn')
    end

    def ipv4_information_trust_all
      config_get('dhcp_relay_global', 'ipv4_information_trust_all')
    end

    def ipv4_information_trust_all=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state)
      config_set('dhcp_relay_global', 'ipv4_information_trust_all', @set_args)
    end

    def default_ipv4_information_trust_all
      config_get_default('dhcp_relay_global', 'ipv4_information_trust_all')
    end

    def ipv4_relay
      config_get('dhcp_relay_global', 'ipv4_relay')
    end

    def ipv4_relay=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state)
      config_set('dhcp_relay_global', 'ipv4_relay', @set_args)
    end

    def default_ipv4_relay
      config_get_default('dhcp_relay_global', 'ipv4_relay')
    end

    def ipv4_smart_relay
      config_get('dhcp_relay_global', 'ipv4_smart_relay')
    end

    def ipv4_smart_relay=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state)
      config_set('dhcp_relay_global', 'ipv4_smart_relay', @set_args)
    end

    def default_ipv4_smart_relay
      config_get_default('dhcp_relay_global', 'ipv4_smart_relay')
    end

    def ipv4_src_addr_hsrp
      config_get('dhcp_relay_global', 'ipv4_src_addr_hsrp')
    end

    def ipv4_src_addr_hsrp=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state)
      config_set('dhcp_relay_global', 'ipv4_src_addr_hsrp', @set_args)
    end

    def default_ipv4_src_addr_hsrp
      config_get_default('dhcp_relay_global', 'ipv4_src_addr_hsrp')
    end

    def ipv4_src_intf
      intf = config_get('dhcp_relay_global', 'ipv4_src_intf')
      # Normalize by downcasing and removing white space
      intf = intf.downcase.delete(' ') if intf
      intf
    end

    def ipv4_src_intf=(val)
      state = val == default_ipv4_src_intf ? 'no' : ''
      intf = val == default_ipv4_src_intf ? '' : val
      set_args_keys(state: state, intf: intf)
      config_set('dhcp_relay_global', 'ipv4_src_intf', @set_args)
    end

    def default_ipv4_src_intf
      config_get_default('dhcp_relay_global', 'ipv4_src_intf')
    end

    def ipv4_sub_option_circuit_id_custom
      config_get('dhcp_relay_global', 'ipv4_sub_option_circuit_id_custom')
    end

    def ipv4_sub_option_circuit_id_custom=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state)
      config_set('dhcp_relay_global', 'ipv4_sub_option_circuit_id_custom',
                 @set_args)
    end

    def default_ipv4_sub_option_circuit_id_custom
      config_get_default('dhcp_relay_global',
                         'ipv4_sub_option_circuit_id_custom')
    end

    def ipv4_sub_option_circuit_id_string
      str = config_get('dhcp_relay_global', 'ipv4_sub_option_circuit_id_string')
      # Normalize by removing white space and add quotes
      if str
        str.strip!
        str = Utils.add_quotes(str)
      end
      str
    end

    def ipv4_sub_option_circuit_id_string=(val)
      state = val == default_ipv4_sub_option_circuit_id_string ? 'no' : ''
      format = val == default_ipv4_sub_option_circuit_id_string ? '' : 'format'
      word = val == default_ipv4_sub_option_circuit_id_string ? '' : val
      word = Utils.add_quotes(word) unless word.empty?
      set_args_keys(state: state, format: format, word: word)
      config_set('dhcp_relay_global', 'ipv4_sub_option_circuit_id_string',
                 @set_args)
    end

    def default_ipv4_sub_option_circuit_id_string
      config_get_default('dhcp_relay_global',
                         'ipv4_sub_option_circuit_id_string')
    end

    def ipv4_sub_option_cisco
      config_get('dhcp_relay_global', 'ipv4_sub_option_cisco')
    end

    def ipv4_sub_option_cisco=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state)
      config_set('dhcp_relay_global', 'ipv4_sub_option_cisco', @set_args)
    end

    def default_ipv4_sub_option_cisco
      config_get_default('dhcp_relay_global', 'ipv4_sub_option_cisco')
    end

    def ipv6_option_cisco
      config_get('dhcp_relay_global', 'ipv6_option_cisco')
    end

    def ipv6_option_cisco=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state)
      config_set('dhcp_relay_global', 'ipv6_option_cisco', @set_args)
    end

    def default_ipv6_option_cisco
      config_get_default('dhcp_relay_global', 'ipv6_option_cisco')
    end

    def ipv6_option_vpn
      config_get('dhcp_relay_global', 'ipv6_option_vpn')
    end

    def ipv6_option_vpn=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state)
      config_set('dhcp_relay_global', 'ipv6_option_vpn', @set_args)
    end

    def default_ipv6_option_vpn
      config_get_default('dhcp_relay_global', 'ipv6_option_vpn')
    end

    def ipv6_relay
      config_get('dhcp_relay_global', 'ipv6_relay')
    end

    def ipv6_relay=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state)
      config_set('dhcp_relay_global', 'ipv6_relay', @set_args)
    end

    def default_ipv6_relay
      config_get_default('dhcp_relay_global', 'ipv6_relay')
    end

    def ipv6_src_intf
      intf = config_get('dhcp_relay_global', 'ipv6_src_intf')
      # Normalize by downcasing and removing white space
      intf = intf.downcase.delete(' ') if intf
      intf
    end

    def ipv6_src_intf=(val)
      state = val == default_ipv6_src_intf ? 'no' : ''
      intf = val == default_ipv6_src_intf ? '' : val
      set_args_keys(state: state, intf: intf)
      config_set('dhcp_relay_global', 'ipv6_src_intf', @set_args)
    end

    def default_ipv6_src_intf
      config_get_default('dhcp_relay_global', 'ipv6_src_intf')
    end
  end # class
end # module
