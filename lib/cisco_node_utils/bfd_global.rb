#
# NXAPI implementation of BFD Global class
#
# May 2016, Sai Chintalapudi
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
  # node_utils class for bfd_global
  class BfdGlobal < NodeUtil
    attr_reader :name

    def initialize(instantiate=true)
      set_args_keys_default

      Feature.bfd_enable if instantiate
    end

    # Reset everything back to default
    def destroy
      return unless Feature.bfd_enabled?
      [:interval,
       :ipv4_interval,
       :ipv6_interval,
       :fabricpath_interval,
       :echo_interface,
       :echo_rx_interval,
       :ipv4_echo_rx_interval,
       :ipv6_echo_rx_interval,
       :fabricpath_vlan,
       :slow_timer,
       :ipv4_slow_timer,
       :ipv6_slow_timer,
       :fabricpath_slow_timer,
       :startup_timer,
      ].each do |prop|
        send("#{prop}=", send("default_#{prop}")) if
          send prop
      end
      set_args_keys_default
    end

    # Helper method to delete @set_args hash keys
    def set_args_keys_default
      keys = { state: '' }
      @get_args = @set_args = keys
    end

    # rubocop:disable Style/AccessorMethodName
    def set_args_keys(hash={})
      set_args_keys_default
      @set_args = @get_args.merge!(hash) unless hash.empty?
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    def echo_interface
      config_get('bfd_global', 'echo_interface', @get_args)
    end

    def echo_interface=(val)
      set_args_keys(intf:  val ? val : echo_interface,
                    state: val ? '' : 'no')
      config_set('bfd_global', 'echo_interface', @set_args) if
        @set_args[:intf]
    end

    def default_echo_interface
      config_get_default('bfd_global', 'echo_interface')
    end

    def echo_rx_interval
      config_get('bfd_global', 'echo_rx_interval', @get_args)
    end

    def echo_rx_interval=(val)
      set_args_keys(rxi:   val,
                    state: val == default_echo_rx_interval ? 'no' : '')
      config_set('bfd_global', 'echo_rx_interval', @set_args)
    end

    def default_echo_rx_interval
      config_get_default('bfd_global', 'echo_rx_interval')
    end

    def ipv4_echo_rx_interval
      config_get('bfd_global', 'ipv4_echo_rx_interval', @get_args)
    end

    def ipv4_echo_rx_interval=(val)
      set_args_keys(rxi:   val,
                    state: val == default_ipv4_echo_rx_interval ? 'no' : '')
      config_set('bfd_global', 'ipv4_echo_rx_interval', @set_args)
    end

    def default_ipv4_echo_rx_interval
      config_get_default('bfd_global', 'ipv4_echo_rx_interval')
    end

    def ipv6_echo_rx_interval
      config_get('bfd_global', 'ipv6_echo_rx_interval', @get_args)
    end

    def ipv6_echo_rx_interval=(val)
      set_args_keys(rxi:   val,
                    state: val == default_ipv6_echo_rx_interval ? 'no' : '')
      config_set('bfd_global', 'ipv6_echo_rx_interval', @set_args)
    end

    def default_ipv6_echo_rx_interval
      config_get_default('bfd_global', 'ipv6_echo_rx_interval')
    end

    def slow_timer
      config_get('bfd_global', 'slow_timer', @get_args)
    end

    def slow_timer=(val)
      set_args_keys(timer: val,
                    state: val == default_slow_timer ? 'no' : '')
      config_set('bfd_global', 'slow_timer', @set_args)
    end

    def default_slow_timer
      config_get_default('bfd_global', 'slow_timer')
    end

    def ipv4_slow_timer
      config_get('bfd_global', 'ipv4_slow_timer', @get_args)
    end

    def ipv4_slow_timer=(val)
      set_args_keys(timer: val,
                    state: val == default_ipv4_slow_timer ? 'no' : '')
      config_set('bfd_global', 'ipv4_slow_timer', @set_args)
    end

    def default_ipv4_slow_timer
      config_get_default('bfd_global', 'ipv4_slow_timer')
    end

    def ipv6_slow_timer
      config_get('bfd_global', 'ipv6_slow_timer', @get_args)
    end

    def ipv6_slow_timer=(val)
      set_args_keys(timer: val,
                    state: val == default_ipv6_slow_timer ? 'no' : '')
      config_set('bfd_global', 'ipv6_slow_timer', @set_args)
    end

    def default_ipv6_slow_timer
      config_get_default('bfd_global', 'ipv6_slow_timer')
    end

    def fabricpath_slow_timer
      config_get('bfd_global', 'fabricpath_slow_timer', @get_args)
    end

    def fabricpath_slow_timer=(val)
      set_args_keys(timer: val,
                    state: val == default_fabricpath_slow_timer ? 'no' : '')
      config_set('bfd_global', 'fabricpath_slow_timer', @set_args)
    end

    def default_fabricpath_slow_timer
      config_get_default('bfd_global', 'fabricpath_slow_timer')
    end

    def startup_timer
      config_get('bfd_global', 'startup_timer', @get_args)
    end

    def startup_timer=(val)
      set_args_keys(timer: val,
                    state: val == default_startup_timer ? 'no' : '')
      config_set('bfd_global', 'startup_timer', @set_args)
    end

    def default_startup_timer
      config_get_default('bfd_global', 'startup_timer')
    end

    def fabricpath_vlan
      config_get('bfd_global', 'fabricpath_vlan', @get_args)
    end

    def fabricpath_vlan=(val)
      set_args_keys(vlan:  val,
                    state: val == default_fabricpath_vlan ? 'no' : '')
      config_set('bfd_global', 'fabricpath_vlan', @set_args)
    end

    def default_fabricpath_vlan
      config_get_default('bfd_global', 'fabricpath_vlan')
    end

    def default_interval
      config_get_default('bfd_global', 'interval')
    end

    def default_ipv4_interval
      config_get_default('bfd_global', 'ipv4_interval')
    end

    def default_ipv6_interval
      config_get_default('bfd_global', 'ipv6_interval')
    end

    def default_fabricpath_interval
      config_get_default('bfd_global', 'fabricpath_interval')
    end

    # interval is an array of interval, min_rx and multiplier
    # CLI: bfd interval 100 min_rx 100 multiplier 25
    def interval
      config_get('bfd_global', 'interval', @get_args)
    end

    # ipv4_interval is an array of ipv4_interval, ipv4_min_rx and
    # ipv4_multiplier
    # CLI: bfd ipv4 interval 100 min_rx 100 multiplier 25
    def ipv4_interval
      config_get('bfd_global', 'ipv4_interval', @get_args)
    end

    # ipv6_interval is an array of ipv6_interval, ipv6_min_rx and
    # ipv6_multiplier
    # CLI: bfd ipv6 interval 100 min_rx 100 multiplier 25
    def ipv6_interval
      config_get('bfd_global', 'ipv6_interval', @get_args)
    end

    # fabricpath_interval is an array of fabricpath_interval,
    # fabricpath_min_rx and fabricpath_multiplier
    # CLI: bfd fabricpath interval 100 min_rx 100 multiplier 25
    def fabricpath_interval
      config_get('bfd_global', 'fabricpath_interval', @get_args)
    end

    # interval is an array of interval, min_rx and multiplier
    # ex: ['100', '100', '25']
    # CLI: bfd interval 100 min_rx 100 multiplier 25
    def interval=(arr)
      interval, min_rx, multiplier = arr
      set_args_keys(interval: interval, min_rx: min_rx, multiplier: multiplier,
                    state: arr == default_interval ? 'no' : '')
      config_set('bfd_global', 'interval', @set_args)
    end

    # ipv4_interval is an array of ipv4_interval, ipv4_min_rx and
    # ipv4_multiplier
    # ex: ['100', '100', '25']
    # CLI: bfd ipv4 interval 100 min_rx 100 multiplier 25
    def ipv4_interval=(arr)
      interval, min_rx, multiplier = arr
      set_args_keys(interval: interval, min_rx: min_rx, multiplier: multiplier,
                    state: arr == default_ipv4_interval ? 'no' : '')
      config_set('bfd_global', 'ipv4_interval', @set_args)
    end

    # ipv6_interval is an array of ipv6_interval, ipv6_min_rx and
    # ipv6_multiplier
    # ex: ['100', '100', '25']
    # CLI: bfd ipv6 interval 100 min_rx 100 multiplier 25
    def ipv6_interval=(arr)
      interval, min_rx, multiplier = arr
      set_args_keys(interval: interval, min_rx: min_rx, multiplier: multiplier,
                    state: arr == default_ipv6_interval ? 'no' : '')
      config_set('bfd_global', 'ipv6_interval', @set_args)
    end

    # fabricpath_interval is an array of fabricpath_interval,
    # fabricpath_min_rx and fabricpath_multiplier
    # ex: ['100', '100', '25']
    # CLI: bfd fabricpath interval 100 min_rx 100 multiplier 25
    def fabricpath_interval=(arr)
      interval, min_rx, multiplier = arr
      set_args_keys(interval: interval, min_rx: min_rx, multiplier: multiplier,
                    state: arr == default_fabricpath_interval ? 'no' : '')
      config_set('bfd_global', 'fabricpath_interval', @set_args)
    end
  end # class
end # module
