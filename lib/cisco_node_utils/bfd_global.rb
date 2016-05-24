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

    def initialize(name, instantiate=true)
      fail ArgumentError unless name.to_s == 'default'
      @name = name.downcase
      set_args_keys_default

      Feature.bfd_enable if instantiate
    end

    def to_s
      "bfd_global #{name}"
    end

    def self.globals
      hash = {}
      hash['default'] = BfdGlobal.new('default', false) if
        Feature.bfd_enabled?
      hash
    end

    # Reset everything back to default
    def destroy
      self.echo_interface = default_echo_interface
      self.echo_rx_interval = default_echo_rx_interval if echo_rx_interval
      self.ipv4_echo_rx_interval = default_ipv4_echo_rx_interval if
      ipv4_echo_rx_interval
      self.ipv6_echo_rx_interval = default_ipv6_echo_rx_interval if
      ipv6_echo_rx_interval
      self.fabricpath_vlan = default_fabricpath_vlan if fabricpath_vlan
      self.slow_timer = default_slow_timer if slow_timer
      self.ipv4_slow_timer = default_ipv4_slow_timer if ipv4_slow_timer
      self.ipv6_slow_timer = default_ipv6_slow_timer if ipv6_slow_timer
      self.fabricpath_slow_timer = default_fabricpath_slow_timer if
      fabricpath_slow_timer
      self.startup_timer = default_startup_timer if startup_timer
      self.interval = default_interval
      self.ipv4_interval = default_ipv4_interval if ipv4_interval
      self.ipv6_interval = default_ipv6_interval if ipv6_interval
      self.fabricpath_interval = default_fabricpath_interval if
      fabricpath_interval
      @name = nil
      set_args_keys_default
    end

    # Helper method to delete @set_args hash keys
    def set_args_keys_default
      keys = { name: @name }
      keys[:state] = ''
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
      if val
        @set_args[:intf] = val
      else
        @set_args[:state] = 'no'
        @set_args[:intf] = echo_interface
      end
      config_set('bfd_global', 'echo_interface', @set_args) if
      @set_args[:intf]
      set_args_keys_default
    end

    def default_echo_interface
      config_get_default('bfd_global', 'echo_interface')
    end

    def echo_rx_interval
      config_get('bfd_global', 'echo_rx_interval', @get_args)
    end

    def echo_rx_interval=(val)
      @set_args[:state] = 'no' if val == default_echo_rx_interval
      @set_args[:rxi] = val
      config_set('bfd_global', 'echo_rx_interval', @set_args)
      set_args_keys_default
    end

    def default_echo_rx_interval
      config_get_default('bfd_global', 'echo_rx_interval')
    end

    def ipv4_echo_rx_interval
      config_get('bfd_global', 'ipv4_echo_rx_interval', @get_args)
    end

    def ipv4_echo_rx_interval=(val)
      @set_args[:state] = 'no' if val == default_ipv4_echo_rx_interval
      @set_args[:rxi] = val
      config_set('bfd_global', 'ipv4_echo_rx_interval', @set_args)
      set_args_keys_default
    end

    def default_ipv4_echo_rx_interval
      config_get_default('bfd_global', 'ipv4_echo_rx_interval')
    end

    def ipv6_echo_rx_interval
      config_get('bfd_global', 'ipv6_echo_rx_interval', @get_args)
    end

    def ipv6_echo_rx_interval=(val)
      @set_args[:state] = 'no' if val == default_ipv6_echo_rx_interval
      @set_args[:rxi] = val
      config_set('bfd_global', 'ipv6_echo_rx_interval', @set_args)
      set_args_keys_default
    end

    def default_ipv6_echo_rx_interval
      config_get_default('bfd_global', 'ipv6_echo_rx_interval')
    end

    def slow_timer
      config_get('bfd_global', 'slow_timer', @get_args)
    end

    def slow_timer=(val)
      @set_args[:state] = 'no' if val == default_slow_timer
      @set_args[:timer] = val
      config_set('bfd_global', 'slow_timer', @set_args)
      set_args_keys_default
    end

    def default_slow_timer
      config_get_default('bfd_global', 'slow_timer')
    end

    def ipv4_slow_timer
      config_get('bfd_global', 'ipv4_slow_timer', @get_args)
    end

    def ipv4_slow_timer=(val)
      @set_args[:state] = 'no' if val == default_ipv4_slow_timer
      @set_args[:timer] = val
      config_set('bfd_global', 'ipv4_slow_timer', @set_args)
      set_args_keys_default
    end

    def default_ipv4_slow_timer
      config_get_default('bfd_global', 'ipv4_slow_timer')
    end

    def ipv6_slow_timer
      config_get('bfd_global', 'ipv6_slow_timer', @get_args)
    end

    def ipv6_slow_timer=(val)
      @set_args[:state] = 'no' if val == default_ipv6_slow_timer
      @set_args[:timer] = val
      config_set('bfd_global', 'ipv6_slow_timer', @set_args)
      set_args_keys_default
    end

    def default_ipv6_slow_timer
      config_get_default('bfd_global', 'ipv6_slow_timer')
    end

    def fabricpath_slow_timer
      config_get('bfd_global', 'fabricpath_slow_timer', @get_args)
    end

    def fabricpath_slow_timer=(val)
      @set_args[:state] = 'no' if val == default_fabricpath_slow_timer
      @set_args[:timer] = val
      config_set('bfd_global', 'fabricpath_slow_timer', @set_args)
      set_args_keys_default
    end

    def default_fabricpath_slow_timer
      config_get_default('bfd_global', 'fabricpath_slow_timer')
    end

    def startup_timer
      config_get('bfd_global', 'startup_timer', @get_args)
    end

    def startup_timer=(val)
      @set_args[:timer] = val
      config_set('bfd_global', 'startup_timer', @set_args)
      set_args_keys_default
    end

    def default_startup_timer
      config_get_default('bfd_global', 'startup_timer')
    end

    def fabricpath_vlan
      config_get('bfd_global', 'fabricpath_vlan', @get_args)
    end

    def fabricpath_vlan=(val)
      @set_args[:vlan] = val
      config_set('bfd_global', 'fabricpath_vlan', @set_args)
      set_args_keys_default
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
    def interval
      config_get('bfd_global', 'interval', @get_args)
    end

    # ipv4_interval is an array of ipv4_interval, ipv4_min_rx and
    # ipv4_multiplier
    def ipv4_interval
      config_get('bfd_global', 'ipv4_interval', @get_args)
    end

    # ipv6_interval is an array of ipv6_interval, ipv6_min_rx and
    # ipv6_multiplier
    def ipv6_interval
      config_get('bfd_global', 'ipv6_interval', @get_args)
    end

    # fabricpath_interval is an array of fabricpath_interval,
    # fabricpath_min_rx and fabricpath_multiplier
    def fabricpath_interval
      config_get('bfd_global', 'fabricpath_interval', @get_args)
    end

    # interval is an array of interval, min_rx and multiplier
    # ex: ['100', '100', '25']
    def interval=(arr)
      @set_args[:state] = 'no' if arr == default_interval
      @set_args[:intv] = arr[0]
      @set_args[:mrx] = arr[1]
      @set_args[:mult] = arr[2]
      config_set('bfd_global', 'interval', @set_args)
      set_args_keys_default
    end

    # ipv4_interval is an array of ipv4_interval, ipv4_min_rx and
    # ipv4_multiplier
    # ex: ['100', '100', '25']
    def ipv4_interval=(arr)
      @set_args[:state] = 'no' if arr == default_ipv4_interval
      @set_args[:intv] = arr[0]
      @set_args[:mrx] = arr[1]
      @set_args[:mult] = arr[2]
      config_set('bfd_global', 'ipv4_interval', @set_args)
      set_args_keys_default
    end

    # ipv6_interval is an array of ipv6_interval, ipv6_min_rx and
    # ipv6_multiplier
    # ex: ['100', '100', '25']
    def ipv6_interval=(arr)
      @set_args[:state] = 'no' if arr == default_ipv6_interval
      @set_args[:intv] = arr[0]
      @set_args[:mrx] = arr[1]
      @set_args[:mult] = arr[2]
      config_set('bfd_global', 'ipv6_interval', @set_args)
      set_args_keys_default
    end

    # fabricpath_interval is an array of fabricpath_interval,
    # fabricpath_min_rx and fabricpath_multiplier
    # ex: ['100', '100', '25']
    def fabricpath_interval=(arr)
      @set_args[:state] = 'no' if arr == default_fabricpath_interval
      @set_args[:intv] = arr[0]
      @set_args[:mrx] = arr[1]
      @set_args[:mult] = arr[2]
      config_set('bfd_global', 'fabricpath_interval', @set_args)
      set_args_keys_default
    end
  end # class
end # module
