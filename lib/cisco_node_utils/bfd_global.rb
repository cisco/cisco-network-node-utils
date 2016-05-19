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

      create if instantiate
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

    def create
      Feature.bfd_enable
      set_args_keys_default
    end

    def destroy
      @name = nil
      Feature.bfd_disable
    end

    # Helper method to delete @set_args hash keys
    def set_args_keys_default
      keys = { name: @name }
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
        @set_args[:state] = ''
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
      if val
        @set_args[:state] = ''
        @set_args[:rxi] = val
      else
        @set_args[:state] = 'no'
        @set_args[:rxi] = ''
      end
      @set_args[:protocol] = ''
      config_set('bfd_global', 'common_echo_rx_interval', @set_args)
      set_args_keys_default
    end

    def default_echo_rx_interval
      config_get_default('bfd_global', 'echo_rx_interval')
    end

    def ipv4_echo_rx_interval
      config_get('bfd_global', 'ipv4_echo_rx_interval', @get_args)
    end

    def ipv4_echo_rx_interval=(val)
      if val
        @set_args[:state] = ''
        @set_args[:rxi] = val
      else
        @set_args[:state] = 'no'
        @set_args[:rxi] = ''
      end
      @set_args[:protocol] = 'ipv4'
      config_set('bfd_global', 'common_echo_rx_interval', @set_args)
      set_args_keys_default
    end

    def default_ipv4_echo_rx_interval
      config_get_default('bfd_global', 'echo_rx_interval')
    end

    def ipv6_echo_rx_interval
      config_get('bfd_global', 'ipv6_echo_rx_interval', @get_args)
    end

    def ipv6_echo_rx_interval=(val)
      if val
        @set_args[:state] = ''
        @set_args[:rxi] = val
      else
        @set_args[:state] = 'no'
        @set_args[:rxi] = ''
      end
      @set_args[:protocol] = 'ipv6'
      config_set('bfd_global', 'common_echo_rx_interval', @set_args)
      set_args_keys_default
    end

    def default_ipv6_echo_rx_interval
      config_get_default('bfd_global', 'echo_rx_interval')
    end

    def slow_timer
      config_get('bfd_global', 'slow_timer', @get_args)
    end

    def slow_timer=(val)
      if val
        @set_args[:state] = ''
        @set_args[:timer] = val
      else
        @set_args[:state] = 'no'
        @set_args[:timer] = ''
      end
      @set_args[:protocol] = ''
      config_set('bfd_global', 'common_slow_timer', @set_args)
      set_args_keys_default
    end

    def default_slow_timer
      config_get_default('bfd_global', 'slow_timer')
    end

    def ipv4_slow_timer
      config_get('bfd_global', 'ipv4_slow_timer', @get_args)
    end

    def ipv4_slow_timer=(val)
      if val
        @set_args[:state] = ''
        @set_args[:timer] = val
      else
        @set_args[:state] = 'no'
        @set_args[:timer] = ''
      end
      @set_args[:protocol] = 'ipv4'
      config_set('bfd_global', 'common_slow_timer', @set_args)
      set_args_keys_default
    end

    def default_ipv4_slow_timer
      config_get_default('bfd_global', 'slow_timer')
    end

    def ipv6_slow_timer
      config_get('bfd_global', 'ipv6_slow_timer', @get_args)
    end

    def ipv6_slow_timer=(val)
      if val
        @set_args[:state] = ''
        @set_args[:timer] = val
      else
        @set_args[:state] = 'no'
        @set_args[:timer] = ''
      end
      @set_args[:protocol] = 'ipv6'
      config_set('bfd_global', 'common_slow_timer', @set_args)
      set_args_keys_default
    end

    def default_ipv6_slow_timer
      config_get_default('bfd_global', 'slow_timer')
    end

    def fabricpath_slow_timer
      config_get('bfd_global', 'fabricpath_slow_timer', @get_args)
    end

    def fabricpath_slow_timer=(val)
      if val
        @set_args[:state] = ''
        @set_args[:timer] = val
      else
        @set_args[:state] = 'no'
        @set_args[:timer] = ''
      end
      @set_args[:protocol] = 'fabricpath'
      config_set('bfd_global', 'common_slow_timer', @set_args)
      set_args_keys_default
    end

    def default_fabricpath_slow_timer
      config_get_default('bfd_global', 'slow_timer')
    end

    def startup_timer
      config_get('bfd_global', 'startup_timer', @get_args)
    end

    def startup_timer=(val)
      if val
        @set_args[:state] = ''
        @set_args[:timer] = val
      else
        @set_args[:state] = 'no'
        @set_args[:timer] = ''
      end
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
      if val
        @set_args[:state] = ''
        @set_args[:vlan] = val
      else
        @set_args[:state] = 'no'
        @set_args[:vlan] = ''
      end
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
      config_get_default('bfd_global', 'interval')
    end

    def default_ipv6_interval
      config_get_default('bfd_global', 'interval')
    end

    def default_fabricpath_interval
      config_get_default('bfd_global', 'interval')
    end

    def default_min_rx
      config_get_default('bfd_global', 'min_rx')
    end

    def default_ipv4_min_rx
      config_get_default('bfd_global', 'min_rx')
    end

    def default_ipv6_min_rx
      config_get_default('bfd_global', 'min_rx')
    end

    def default_fabricpath_min_rx
      config_get_default('bfd_global', 'min_rx')
    end

    def default_multiplier
      config_get_default('bfd_global', 'multiplier')
    end

    def default_ipv4_multiplier
      config_get_default('bfd_global', 'multiplier')
    end

    def default_ipv6_multiplier
      config_get_default('bfd_global', 'multiplier')
    end

    def default_fabricpath_multiplier
      config_get_default('bfd_global', 'multiplier')
    end

    def interval_get(protocol)
      case protocol.to_sym
      when :ipv4
        config_get('bfd_global', 'ipv4_interval', @get_args)
      when :ipv6
        config_get('bfd_global', 'ipv6_interval', @get_args)
      when :fabricpath
        config_get('bfd_global', 'fabricpath_interval', @get_args)
      else
        config_get('bfd_global', 'interval', @get_args)
      end
    end

    def interval
      interval_get('')[0]
    end

    def ipv4_interval
      interval_get('ipv4')[0]
    end

    def ipv6_interval
      interval_get('ipv6')[0]
    end

    def fabricpath_interval
      interval_get('fabricpath')[0]
    end

    def min_rx
      interval_get('')[1]
    end

    def ipv4_min_rx
      interval_get('ipv4')[1]
    end

    def ipv6_min_rx
      interval_get('ipv6')[1]
    end

    def fabricpath_min_rx
      interval_get('fabricpath')[1]
    end

    def multiplier
      interval_get('')[2]
    end

    def ipv4_multiplier
      interval_get('ipv4')[2]
    end

    def ipv6_multiplier
      interval_get('ipv6')[2]
    end

    def fabricpath_multiplier
      interval_get('fabricpath')[2]
    end

    def interval=(val)
      @set_args[:intv] = val
      @set_args[:protocol] = ''
    end

    def ipv4_interval=(val)
      @set_args[:intv] = val
      @set_args[:protocol] = 'ipv4'
    end

    def ipv6_interval=(val)
      @set_args[:intv] = val
      @set_args[:protocol] = 'ipv6'
    end

    def fabricpath_interval=(val)
      @set_args[:intv] = val
      @set_args[:protocol] = 'fabricpath'
    end

    def min_rx=(val)
      @set_args[:mrx] = val
      @set_args[:protocol] = ''
    end

    def ipv4_min_rx=(val)
      @set_args[:mrx] = val
      @set_args[:protocol] = 'ipv4'
    end

    def ipv6_min_rx=(val)
      @set_args[:mrx] = val
      @set_args[:protocol] = 'ipv6'
    end

    def fabricpath_min_rx=(val)
      @set_args[:mrx] = val
      @set_args[:protocol] = 'fabricpath'
    end

    def multiplier=(val)
      @set_args[:mult] = val
      @set_args[:protocol] = ''
    end

    def ipv4_multiplier=(val)
      @set_args[:mult] = val
      @set_args[:protocol] = 'ipv4'
    end

    def ipv6_multiplier=(val)
      @set_args[:mult] = val
      @set_args[:protocol] = 'ipv6'
    end

    def fabricpath_multiplier=(val)
      @set_args[:mult] = val
      @set_args[:protocol] = 'fabricpath'
    end

    def interval_set(attrs)
      set_args_keys(attrs)
      [:interval,
       :protocol,
       :min_rx,
       :multiplier,
      ].each do |p|
        attrs[p] = '' if attrs[p].nil?
        send(p.to_s + '=', attrs[p])
      end
      @set_args[:state] = ''
      @set_args[:state] = 'no' if
        @set_args[:intv] == default_interval &&
        @set_args[:mrx] == default_min_rx &&
        @set_args[mult] == default_multiplier
      config_set('itd_service', 'load_balance', @set_args)
      set_args_keys_default
    end
  end # class
end # module
