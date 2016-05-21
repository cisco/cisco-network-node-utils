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

    # Reset everything back to default
    def destroy
      self.echo_interface = default_echo_interface
      config_set('bfd_global', 'common_echo_rx_interval', state: 'no',
                 protocol: '', rxi: '') unless type == 'fabric'
      config_set('bfd_global', 'common_echo_rx_interval', state: 'no',
                 protocol: 'ipv4', rxi: '') unless type == 'fabric'
      config_set('bfd_global', 'common_echo_rx_interval', state: 'no',
                 protocol: 'ipv6', rxi: '') unless type == 'fabric'
      config_set('bfd_global', 'fabricpath_vlan', state: 'no', vlan: '') if
      fabricpath_vlan
      config_set('bfd_global', 'common_slow_timer', state: 'no',
                 protocol: '', timer: 1000)
      config_set('bfd_global', 'common_slow_timer', state: 'no',
                 protocol: 'ipv4', timer: '') unless type == 'fabric'
      config_set('bfd_global', 'common_slow_timer', state: 'no',
                 protocol: 'ipv6', timer: '') unless type == 'fabric'
      config_set('bfd_global', 'common_slow_timer', state: 'no',
                 protocol: 'fabricpath', timer: '') unless type == 'ip'
      config_set('bfd_global', 'startup_timer', state: 'no', timer: '') if
      startup_timer
      config_set('bfd_global', 'common_interval', state: 'no',
                 protocol: '', intv: 50, mrx: 50, mult: 3) unless
      type == 'ip' # this is workaround due to a bug on nexus platform
      config_set('bfd_global', 'common_interval', state: 'no',
                 protocol: 'ipv4', intv: 50, mrx: 50, mult: 3) unless
      type == 'fabric'
      config_set('bfd_global', 'common_interval', state: 'no',
                 protocol: 'ipv6', intv: 50, mrx: 50, mult: 3) unless
      type == 'fabric'
      config_set('bfd_global', 'common_interval', state: 'no',
                 protocol: 'fabricpath', intv: 50, mrx: 50, mult: 3) unless
      type == 'ip'
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

    def type
      config_get('bfd_global', 'type', @get_args)
    end

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

    # there are multiple variations of the CLI for echo_rx_interval
    # the difference is only in protocol
    # bfd echo-rx-interval 50
    # bfd ipv4 echo-rx-interval 50
    # bfd ipv6 echo-rx-interval 50
    def common_echo_rx_interval_get(protocol)
      @get_args[:protocol] = protocol
      config_get('bfd_global', 'common_echo_rx_interval', @get_args).to_i
    end

    def common_echo_rx_interval_set(protocol, val)
      @set_args[:rxi] = val
      @set_args[:protocol] = protocol
      config_set('bfd_global', 'common_echo_rx_interval', @set_args)
      set_args_keys_default
    end

    def echo_rx_interval
      common_echo_rx_interval_get('')
    end

    def echo_rx_interval=(val)
      common_echo_rx_interval_set('', val)
    end

    def default_echo_rx_interval
      config_get_default('bfd_global', 'echo_rx_interval')
    end

    def ipv4_echo_rx_interval
      common_echo_rx_interval_get('ipv4 ')
    end

    def ipv4_echo_rx_interval=(val)
      common_echo_rx_interval_set('ipv4', val)
    end

    def default_ipv4_echo_rx_interval
      config_get_default('bfd_global', 'echo_rx_interval')
    end

    def ipv6_echo_rx_interval
      common_echo_rx_interval_get('ipv6 ')
    end

    def ipv6_echo_rx_interval=(val)
      common_echo_rx_interval_set('ipv6', val)
    end

    def default_ipv6_echo_rx_interval
      config_get_default('bfd_global', 'echo_rx_interval')
    end

    # there are multiple variations of the CLI for slow-timer
    # the difference is only in protocol
    # bfd slow-timer 2000
    # bfd ipv4 slow-timer 2000
    # bfd ipv6 slow-timer 2000
    # bfd fabricpath slow-timer 2000
    def common_slow_timer_get(protocol)
      @get_args[:protocol] = protocol
      config_get('bfd_global', 'common_slow_timer', @get_args).to_i
    end

    def common_slow_timer_set(protocol, val)
      @set_args[:timer] = val
      @set_args[:protocol] = protocol
      config_set('bfd_global', 'common_slow_timer', @set_args)
      set_args_keys_default
    end

    def slow_timer
      common_slow_timer_get('')
    end

    def slow_timer=(val)
      common_slow_timer_set('', val)
    end

    def default_slow_timer
      config_get_default('bfd_global', 'slow_timer')
    end

    def ipv4_slow_timer
      common_slow_timer_get('ipv4 ')
    end

    def ipv4_slow_timer=(val)
      common_slow_timer_set('ipv4', val)
    end

    def default_ipv4_slow_timer
      config_get_default('bfd_global', 'slow_timer')
    end

    def ipv6_slow_timer
      common_slow_timer_get('ipv6 ')
    end

    def ipv6_slow_timer=(val)
      common_slow_timer_set('ipv6', val)
    end

    def default_ipv6_slow_timer
      config_get_default('bfd_global', 'slow_timer')
    end

    def fabricpath_slow_timer
      common_slow_timer_get('fabricpath ')
    end

    def fabricpath_slow_timer=(val)
      common_slow_timer_set('fabricpath', val)
    end

    def default_fabricpath_slow_timer
      config_get_default('bfd_global', 'slow_timer')
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

    # there are multiple variations of the CLI for interval related CLI
    # the difference is only in protocol
    # bfd interval 50 min_rx 50 multiplier 3
    # bfd ipv4 interval 50 min_rx 50 multiplier 3
    # bfd ipv6 interval 50 min_rx 50 multiplier 3
    # bfd fabricpath interval 50 min_rx 50 multiplier 3
    def interval_params_get(protocol)
      @get_args[:protocol] = protocol
      config_get('bfd_global', 'common_interval', @get_args).map(&:to_i)
    end

    def interval
      interval_params_get('')[0]
    end

    def ipv4_interval
      interval_params_get('ipv4 ')[0]
    end

    def ipv6_interval
      interval_params_get('ipv6 ')[0]
    end

    def fabricpath_interval
      interval_params_get('fabricpath ')[0]
    end

    def min_rx
      interval_params_get('')[1]
    end

    def ipv4_min_rx
      interval_params_get('ipv4 ')[1]
    end

    def ipv6_min_rx
      interval_params_get('ipv6 ')[1]
    end

    def fabricpath_min_rx
      interval_params_get('fabricpath ')[1]
    end

    def multiplier
      interval_params_get('')[2]
    end

    def ipv4_multiplier
      interval_params_get('ipv4 ')[2]
    end

    def ipv6_multiplier
      interval_params_get('ipv6 ')[2]
    end

    def fabricpath_multiplier
      interval_params_get('fabricpath ')[2]
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

    def interval_params_set(attrs, protocol)
      if protocol.empty?
        set_args_keys(attrs)
        [:interval,
         :min_rx,
         :multiplier,
        ].each do |p|
          send(p.to_s + '=', attrs[p])
        end
        @set_args[:protocol] = ''
      else
        case protocol.to_sym
        when :ipv4
          set_args_keys(attrs)
          [:ipv4_interval,
           :ipv4_min_rx,
           :ipv4_multiplier,
          ].each do |p|
            send(p.to_s + '=', attrs[p])
          end
          @set_args[:protocol] = 'ipv4'
        when :ipv6
          set_args_keys(attrs)
          [:ipv6_interval,
           :ipv6_min_rx,
           :ipv6_multiplier,
          ].each do |p|
            send(p.to_s + '=', attrs[p])
          end
          @set_args[:protocol] = 'ipv6'
        when :fabricpath
          set_args_keys(attrs)
          [:fabricpath_interval,
           :fabricpath_min_rx,
           :fabricpath_multiplier,
          ].each do |p|
            send(p.to_s + '=', attrs[p])
          end
          @set_args[:protocol] = 'fabricpath'
        end
      end
      config_set('bfd_global', 'common_interval', @set_args)
      set_args_keys_default
    end
  end # class
end # module
