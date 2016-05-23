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
      self.fabricpath_vlan = default_fabricpath_vlan if fabricpath_vlan
      self.slow_timer = default_slow_timer if slow_timer
      self.ipv4_slow_timer = default_ipv4_slow_timer if ipv4_slow_timer
      self.ipv6_slow_timer = default_ipv6_slow_timer if ipv6_slow_timer
      self.fabricpath_slow_timer = default_fabricpath_slow_timer if
      fabricpath_slow_timer
      self.startup_timer = default_startup_timer if startup_timer
      config_set('bfd_global', 'interval', state: 'no',
                 intv: 50, mrx: 50, mult: 3)
      config_set('bfd_global', 'ipv4_interval', state: 'no',
                 intv: 50, mrx: 50, mult: 3) if ipv4_interval
      config_set('bfd_global', 'ipv6_interval', state: 'no',
                 intv: 50, mrx: 50, mult: 3) if ipv6_interval
      config_set('bfd_global', 'fabricpath_interval', state: 'no',
                 intv: 50, mrx: 50, mult: 3) if fabricpath_interval
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

    def default_min_rx
      config_get_default('bfd_global', 'min_rx')
    end

    def default_ipv4_min_rx
      config_get_default('bfd_global', 'ipv4_min_rx')
    end

    def default_ipv6_min_rx
      config_get_default('bfd_global', 'ipv6_min_rx')
    end

    def default_fabricpath_min_rx
      config_get_default('bfd_global', 'fabricpath_min_rx')
    end

    def default_multiplier
      config_get_default('bfd_global', 'multiplier')
    end

    def default_ipv4_multiplier
      config_get_default('bfd_global', 'ipv4_multiplier')
    end

    def default_ipv6_multiplier
      config_get_default('bfd_global', 'ipv6_multiplier')
    end

    def default_fabricpath_multiplier
      config_get_default('bfd_global', 'fabricpath_multiplier')
    end

    def interval_get
      config_get('bfd_global', 'interval_param', @get_args).map(&:to_i)
    end

    def ipv4_interval_get
      config_get('bfd_global', 'ipv4_interval_param', @get_args).map(&:to_i)
    end

    def ipv6_interval_get
      config_get('bfd_global', 'ipv6_interval_param', @get_args).map(&:to_i)
    end

    def fabricpath_interval_get
      config_get('bfd_global',
                 'fabricpath_interval_param', @get_args).map(&:to_i)
    end

    def interval
      interval_get[0]
    end

    def ipv4_interval
      ipv4_interval_get[0]
    end

    def ipv6_interval
      ipv6_interval_get[0]
    end

    def fabricpath_interval
      fabricpath_interval_get[0]
    end

    def min_rx
      interval_get[1]
    end

    def ipv4_min_rx
      ipv4_interval_get[1]
    end

    def ipv6_min_rx
      ipv6_interval_get[1]
    end

    def fabricpath_min_rx
      fabricpath_interval_get[1]
    end

    def multiplier
      interval_get[2]
    end

    def ipv4_multiplier
      ipv4_interval_get[2]
    end

    def ipv6_multiplier
      ipv6_interval_get[2]
    end

    def fabricpath_multiplier
      fabricpath_interval_get[2]
    end

    def interval=(val)
      @set_args[:intv] = val
    end

    def ipv4_interval=(val)
      @set_args[:intv] = val
    end

    def ipv6_interval=(val)
      @set_args[:intv] = val
    end

    def fabricpath_interval=(val)
      @set_args[:intv] = val
    end

    def min_rx=(val)
      @set_args[:mrx] = val
    end

    def ipv4_min_rx=(val)
      @set_args[:mrx] = val
    end

    def ipv6_min_rx=(val)
      @set_args[:mrx] = val
    end

    def fabricpath_min_rx=(val)
      @set_args[:mrx] = val
    end

    def multiplier=(val)
      @set_args[:mult] = val
    end

    def ipv4_multiplier=(val)
      @set_args[:mult] = val
    end

    def ipv6_multiplier=(val)
      @set_args[:mult] = val
    end

    def fabricpath_multiplier=(val)
      @set_args[:mult] = val
    end

    def interval_set(attrs)
      set_args_keys(attrs)
      [:interval,
       :min_rx,
       :multiplier,
      ].each do |p|
        send(p.to_s + '=', attrs[p])
      end
      @set_args[:state] = 'no' if
        @set_args[:intv] == default_interval &&
        @set_args[:mrx] == default_min_rx &&
        @set_args[:mult] == default_multiplier
      config_set('bfd_global', 'interval_param', @set_args)
      set_args_keys_default
    end

    def ipv4_interval_set(attrs)
      set_args_keys(attrs)
      [:ipv4_interval,
       :ipv4_min_rx,
       :ipv4_multiplier,
      ].each do |p|
        send(p.to_s + '=', attrs[p])
      end
      @set_args[:state] = 'no' if
        @set_args[:intv] == default_ipv4_interval &&
        @set_args[:mrx] == default_ipv4_min_rx &&
        @set_args[:mult] == default_ipv4_multiplier
      config_set('bfd_global', 'ipv4_interval_param', @set_args)
      set_args_keys_default
    end

    def ipv6_interval_set(attrs)
      set_args_keys(attrs)
      [:ipv6_interval,
       :ipv6_min_rx,
       :ipv6_multiplier,
      ].each do |p|
        send(p.to_s + '=', attrs[p])
      end
      @set_args[:state] = 'no' if
        @set_args[:intv] == default_ipv6_interval &&
        @set_args[:mrx] == default_ipv6_min_rx &&
        @set_args[:mult] == default_ipv6_multiplier
      config_set('bfd_global', 'ipv6_interval_param', @set_args)
      set_args_keys_default
    end

    def fabricpath_interval_set(attrs)
      set_args_keys(attrs)
      [:fabricpath_interval,
       :fabricpath_min_rx,
       :fabricpath_multiplier,
      ].each do |p|
        send(p.to_s + '=', attrs[p])
      end
      @set_args[:state] = 'no' if
        @set_args[:intv] == default_fabricpath_interval &&
        @set_args[:mrx] == default_fabricpath_min_rx &&
        @set_args[:mult] == default_fabricpath_multiplier
      config_set('bfd_global', 'fabricpath_interval_param', @set_args)
      set_args_keys_default
    end
  end # class
end # module
