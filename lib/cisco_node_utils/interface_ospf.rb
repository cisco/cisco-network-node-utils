# March 2015, Alex Hunsberger
#
# Copyright (c) 2015-2017 Cisco and/or its affiliates.
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

require 'ipaddr'
require_relative 'node_util'
require_relative 'interface'
# Interestingly enough, interface OSPF configuration can exist completely
# independent of router OSPF configuration... so we don't need RouterOspf here.

module Cisco
  # InterfaceOspf - node utility class for per-interface OSPF config management
  class InterfaceOspf < NodeUtil
    attr_reader :intf_name, :ospf_name, :area
    attr_accessor :get_args

    def initialize(intf_name, ospf_name, area, create=true)
      fail TypeError unless intf_name.is_a? String
      fail TypeError unless ospf_name.is_a? String
      fail TypeError unless area.is_a? String
      fail ArgumentError unless intf_name.length > 0
      fail ArgumentError unless ospf_name.length > 0
      fail ArgumentError unless area.length > 0

      # normalize
      @intf_name = intf_name.downcase
      fail "interface #{@intf_name} does not exist" if
        Interface.interfaces[@intf_name].nil?

      @ospf_name = ospf_name
      @area = area
      @get_args = { name: intf_name, show_name: nil }
      set_args_keys_default

      return unless create
      Feature.ospf_enable
      self.area = area
    end

    def set_args_keys_default
      @set_args = { name: @intf_name, ospf_name: @ospf_name, area: @area }
    end

    # can't re-use Interface.interfaces because we need to filter based on
    # "ip router ospf <name>", which Interface doesn't retrieve
    def self.interfaces(ospf_name=nil, single_intf=nil)
      fail TypeError unless ospf_name.is_a?(String) || ospf_name.nil?
      ints = {}
      single_intf ||= ''
      intf_list = config_get('interface_ospf', 'all_interfaces',
                             show_name: single_intf)
      return ints if intf_list.nil?
      intf_list.each do |name|
        # Find interfaces with 'ip router ospf <name> area <area>'
        match = config_get('interface_ospf', 'area',
                           name: name, show_name: single_intf)
        next if match.nil?
        ospf = match[0]
        area = match[1]
        next unless ospf_name.nil? || ospf == ospf_name
        int = name.downcase
        ints[int] = InterfaceOspf.new(int, ospf, area, false)
        ints[int].get_args[:show_name] = single_intf
      end
      ints
    end

    def area
      match = config_get('interface_ospf', 'area', @get_args)
      return nil if match.nil?
      val = match[1]
      # Coerce numeric area to the expected dot-decimal format.
      val = IPAddr.new(val.to_i, Socket::AF_INET).to_s unless val.match(/\./)
      val
    end

    def area=(a)
      config_set('interface_ospf', 'area',
                 @set_args.merge!(state: '', area: a))
      set_args_keys_default
    end

    def destroy
      config_set('interface_ospf', 'area', @set_args.merge!(state: 'no'))
      set_args_keys_default
      # Reset everything else back to default as well:
      self.message_digest = default_message_digest
      message_digest_key_set(default_message_digest_key_id, '', '', '')
      self.cost = default_cost
      destroy_hello_interval
      destroy_dead_interval
      self.bfd = default_bfd
      self.mtu_ignore = default_mtu_ignore
      self.priority = default_priority
      self.network_type = default_network_type
      self.passive_interface = default_passive_interface if passive_interface
      self.shutdown = default_shutdown
      self.transmit_delay = default_transmit_delay
    end

    def default_message_digest
      config_get_default('interface_ospf', 'message_digest')
    end

    def message_digest
      config_get('interface_ospf', 'message_digest', @get_args)
    end

    def message_digest=(enable)
      return if enable == message_digest
      @set_args[:state] = (enable ? '' : 'no')
      config_set('interface_ospf', 'message_digest', @set_args)
      set_args_keys_default
    end

    def default_message_digest_key_id
      config_get_default('interface_ospf', 'message_digest_key_id')
    end

    def message_digest_key_id
      config_get('interface_ospf', 'message_digest_key_id', @get_args)
    end

    def default_message_digest_algorithm_type
      config_get_default('interface_ospf',
                         'message_digest_alg_type').to_sym
    end

    def message_digest_algorithm_type
      match = config_get('interface_ospf', 'message_digest_alg_type',
                         @get_args)
      match.to_sym
    end

    def default_message_digest_encryption_type
      Encryption.cli_to_symbol(
        config_get_default('interface_ospf', 'message_digest_enc_type'))
    end

    def message_digest_encryption_type
      match = config_get('interface_ospf', 'message_digest_enc_type',
                         @get_args)
      Encryption.cli_to_symbol(match)
    end

    def message_digest_password
      config_get('interface_ospf', 'message_digest_password', @get_args)
    end

    def default_message_digest_password
      config_get_default('interface_ospf', 'message_digest_password')
    end

    def message_digest_key_set(keyid, algtype, enctype, enc)
      current_keyid = message_digest_key_id
      if keyid == default_message_digest_key_id && current_keyid != keyid
        @set_args.merge!(state:   'no',
                         keyid:   current_keyid,
                         algtype: '',
                         enctype: '',
                         enc:     '')
        config_set('interface_ospf', 'message_digest_key_set', @set_args)
      elsif keyid != default_message_digest_key_id
        fail TypeError unless enc.is_a?(String)
        fail ArgumentError unless enc.length > 0
        enctype = Encryption.symbol_to_cli(enctype)
        @set_args.merge!(state:   '',
                         keyid:   current_keyid,
                         algtype: algtype,
                         enctype: enctype,
                         enc:     enc)
        config_set('interface_ospf', 'message_digest_key_set', @set_args)
      end
      set_args_keys_default
    end

    def cost
      config_get('interface_ospf', 'cost', @get_args)
    end

    def default_cost
      config_get_default('interface_ospf', 'cost')
    end

    def cost=(c)
      if c == default_cost
        @set_args.merge!(state: 'no', cost: '')
      else
        @set_args.merge!(state: '', cost: c)
      end
      config_set('interface_ospf', 'cost', @set_args)
      set_args_keys_default
    end

    def hello_interval
      config_get('interface_ospf', 'hello_interval', @get_args)
    end

    def default_hello_interval
      config_get_default('interface_ospf', 'hello_interval')
    end

    def hello_interval=(interval)
      # Previous behavior always sets interval and ignores 'no' cmd
      @set_args.merge!(state: '', interval: interval.to_i)
      config_set('interface_ospf', 'hello_interval', @set_args)
      set_args_keys_default
    end

    def destroy_hello_interval
      # Helper to remove cli completely
      @set_args.merge!(state: 'no', interval: '')
      config_set('interface_ospf', 'hello_interval', @set_args)
      set_args_keys_default
    end

    def dead_interval
      config_get('interface_ospf', 'dead_interval', @get_args)
    end

    def default_dead_interval
      config_get_default('interface_ospf', 'dead_interval')
    end

    def dead_interval=(interval)
      # Previous behavior always sets interval and ignores 'no' cmd
      @set_args.merge!(state: '', interval: interval.to_i)
      config_set('interface_ospf', 'dead_interval', @set_args)
      set_args_keys_default
    end

    def destroy_dead_interval
      # Helper to remove cli completely
      @set_args.merge!(state: 'no', interval: '')
      config_set('interface_ospf', 'dead_interval', @set_args)
      set_args_keys_default
    end

    # CLI can be either of the following or none
    # ip ospf bfd
    # ip ospf bfd disable
    def bfd
      val = config_get('interface_ospf', 'bfd', @get_args)
      return if val.nil?
      val.include?('disable') ? false : true
    end

    def bfd=(val)
      return if val == bfd
      Feature.bfd_enable
      state = (val == default_bfd) ? 'no' : ''
      disable = val ? '' : 'disable'
      config_set('interface_ospf', 'bfd',
                 @set_args.merge!(state: state, disable: disable))
      set_args_keys_default
    end

    def default_bfd
      config_get_default('interface_ospf', 'bfd')
    end

    def default_network_type
      case @intf_name
      when /loopback/i
        lookup = 'network_type_loopback_default'
      else
        lookup = 'network_type_default'
      end
      config_get_default('interface_ospf', lookup)
    end

    def mtu_ignore
      config_get('interface_ospf', 'mtu_ignore', @get_args)
    end

    def mtu_ignore=(enable)
      @set_args[:state] = enable ? '' : 'no'
      config_set('interface_ospf', 'mtu_ignore', @set_args)
      set_args_keys_default
    end

    def default_mtu_ignore
      config_get_default('interface_ospf', 'mtu_ignore')
    end

    def network_type
      type = config_get('interface_ospf', 'network_type', @get_args)
      return 'p2p' if type == 'point-to-point'
      return default_network_type if type.nil?
      type
    end

    def network_type=(type)
      if type == default_network_type
        @set_args.merge!(state: 'no', network_type: '')
      else
        network = 'point-to-point' if type.to_s == 'p2p'
        @set_args.merge!(state: '', network_type: network)
      end
      config_set('interface_ospf', 'network_type', @set_args)
      set_args_keys_default
    end

    def default_passive_interface
      config_get_default('interface_ospf', 'passive_interface')
    end

    def passive_interface
      config_get('interface_ospf', 'passive_interface', @get_args)
    end

    def passive_interface=(enable)
      fail TypeError unless enable == true || enable == false
      @set_args[:state] = enable ? '' : 'no'
      config_set('interface_ospf', 'passive_interface', @set_args)
      set_args_keys_default
    end

    def priority
      config_get('interface_ospf', 'priority', @get_args)
    end

    def priority=(val)
      if val == default_priority
        @set_args.merge!(state: 'no', priority: '')
      else
        @set_args.merge!(state: '', priority: val)
      end
      config_set('interface_ospf', 'priority', @set_args)
      set_args_keys_default
    end

    def default_priority
      config_get_default('interface_ospf', 'priority')
    end

    def shutdown
      config_get('interface_ospf', 'shutdown', @get_args)
    end

    def shutdown=(enable)
      @set_args[:state] = enable ? '' : 'no'
      config_set('interface_ospf', 'shutdown', @set_args)
      set_args_keys_default
    end

    def default_shutdown
      config_get_default('interface_ospf', 'shutdown')
    end

    def transmit_delay
      config_get('interface_ospf', 'transmit_delay', @get_args)
    end

    def transmit_delay=(val)
      if val == default_transmit_delay
        @set_args.merge!(state: 'no', delay: '')
      else
        @set_args.merge!(state: '', delay: val)
      end
      config_set('interface_ospf', 'transmit_delay', @set_args)
      set_args_keys_default
    end

    def default_transmit_delay
      config_get_default('interface_ospf', 'transmit_delay')
    end
  end
end
