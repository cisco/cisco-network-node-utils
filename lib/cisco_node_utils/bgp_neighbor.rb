# BGP neighbor provider class
#
# August 2015, Jie Yang
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

require 'ipaddr'
require_relative 'cisco_cmn_utils'
require_relative 'node_util'
require_relative 'feature'
require_relative 'bgp'

module Cisco
  # RouterBgpNeighbor - node utility class for BGP neighbor configs
  class RouterBgpNeighbor < NodeUtil
    attr_reader :nbr, :vrf, :asn

    def initialize(asn, vrf, nbr, instantiate=true)
      fail TypeError unless nbr.is_a?(String)
      # for IP/prefix format, such as "1.1.1.1/24" or "2000:123:38::34/64",
      # we need to mask the address using prefix length, so that it becomes
      # something like "1.1.1.0/24" or "2000:123:38::/64"
      @nbr = Utils.process_network_mask(nbr)
      @asn = RouterBgp.validate_asnum(asn)
      @vrf = vrf
      @get_args = @set_args = { asnum: @asn, nbr: @nbr }
      @get_args[:vrf] = @set_args[:vrf] = vrf if vrf != 'default'

      create if instantiate
    end

    def self.neighbors
      hash = {}
      RouterBgp.routers.each do |asn, vrf|
        hash[asn] = {}
        vrf.each_key do |vrf_id|
          get_args = { asnum: asn }
          get_args[:vrf] = vrf_id unless vrf_id == 'default'
          neighbor_list = config_get('bgp_neighbor', 'all_neighbors', get_args)
          next if neighbor_list.nil?

          hash[asn][vrf_id] = {}
          neighbor_list.each do |nbr|
            hash[asn][vrf_id][nbr] = RouterBgpNeighbor.new(asn, vrf_id,
                                                           nbr, false)
          end
        end
      end
      hash
    rescue Cisco::CliError => e
      # Raise the error unless the error message contains "Syntax error", which
      # means the error was caused by feature is not enabled.
      raise unless e.clierror =~ /Syntax error/
      return {}
    end

    def create
      Feature.bgp_enable
      set_args_keys(state: '')
      config_set('bgp', 'create_destroy_neighbor', @set_args)
    end

    def destroy
      set_args_keys(state: 'no')
      config_set('bgp', 'create_destroy_neighbor', @set_args)
    end

    def set_args_keys_default
      keys = { asnum: @asn, nbr: @nbr }
      keys[:vrf] = @vrf unless @vrf == 'default'
      @set_args = keys
    end

    def set_args_keys(hash={}) # rubocop:disable Style/AccessorMethodName
      set_args_keys_default
      @set_args = @set_args.merge!(hash) unless hash.empty?
    end

    def description=(desc)
      fail TypeError unless desc.is_a?(String)
      desc.strip!
      set_args_keys(state: desc.empty? ? 'no' : '',
                    desc:  desc)
      config_set('bgp_neighbor', 'description', @set_args)
    end

    def description
      config_get('bgp_neighbor', 'description', @get_args)
    end

    def default_description
      config_get_default('bgp_neighbor', 'description')
    end

    def connected_check=(val)
      # the cli is "disable-connected-check", therefore when val is true, we
      # need to set set state to "no"
      set_args_keys(state: (val) ? 'no' : '')
      config_set('bgp_neighbor', 'connected_check', @set_args)
    end

    def connected_check
      result = config_get('bgp_neighbor', 'connected_check', @get_args)
      result ? false : true
    end

    def default_connected_check
      config_get_default('bgp_neighbor', 'connected_check')
    end

    def capability_negotiation=(val)
      # the cli is "dont-capability-negotiate". Therefore when val is true, we
      # need to set state to "no"
      set_args_keys(state: (val) ? 'no' : '')
      config_set('bgp_neighbor', 'capability_negotiation', @set_args)
    end

    def capability_negotiation
      result = config_get('bgp_neighbor', 'capability_negotiation', @get_args)
      result ? false : true
    end

    def default_capability_negotiation
      config_get_default('bgp_neighbor', 'capability_negotiation')
    end

    def dynamic_capability=(val)
      set_args_keys(state: (val) ? '' : 'no')
      config_set('bgp_neighbor', 'dynamic_capability', @set_args)
    end

    def dynamic_capability
      result = config_get('bgp_neighbor', 'dynamic_capability', @get_args)
      result ? true : false
    end

    def default_dynamic_capability
      config_get_default('bgp_neighbor', 'dynamic_capability')
    end

    def ebgp_multihop=(ttl)
      set_args_keys(state: (ttl == default_ebgp_multihop) ? 'no' : '',
                    ttl:   (ttl == default_ebgp_multihop) ? '' : ttl)
      config_set('bgp_neighbor', 'ebgp_multihop', @set_args)
    end

    def ebgp_multihop
      result = config_get('bgp_neighbor', 'ebgp_multihop', @get_args)
      result.nil? ? default_ebgp_multihop : result.to_i
    end

    def default_ebgp_multihop
      config_get_default('bgp_neighbor', 'ebgp_multihop')
    end

    def local_as=(val)
      if val == default_local_as
        set_args_keys(state: 'no', local_as: '')
      else
        set_args_keys(state: '', local_as: val)
      end
      config_set('bgp_neighbor', 'local_as', @set_args)
    end

    def local_as
      config_get('bgp_neighbor', 'local_as', @get_args).to_s
    end

    def default_local_as
      config_get_default('bgp_neighbor', 'local_as').to_s
    end

    def log_neighbor_changes=(val)
      val = val.to_sym
      if val == default_log_neighbor_changes
        set_args_keys(state: 'no', disable: '')
      else
        set_args_keys(state:   '',
                      disable: (val == :enable) ? '' : 'disable')
      end
      config_set('bgp_neighbor', 'log_neighbor_changes', @set_args)
    end

    def log_neighbor_changes
      result = config_get('bgp_neighbor', 'log_neighbor_changes', @get_args)
      return default_log_neighbor_changes if result.nil?
      return :disable if /disable/.match(result.first)
      :enable
    end

    def default_log_neighbor_changes
      result = config_get_default('bgp_neighbor', 'log_neighbor_changes')
      result.to_sym unless result.nil?
    end

    def low_memory_exempt=(val)
      set_args_keys(state: (val) ? '' : 'no')
      config_set('bgp_neighbor', 'low_memory_exempt', @set_args)
    end

    def low_memory_exempt
      result = config_get('bgp_neighbor', 'low_memory_exempt', @get_args)
      result ? true : false
    end

    def default_low_memory_exempt
      config_get_default('bgp_neighbor', 'low_memory_exempt')
    end

    def maximum_peers=(val)
      set_args_keys(state: (val == default_maximum_peers) ? 'no' : '',
                    num:   (val == default_maximum_peers) ? '' : val)
      config_set('bgp_neighbor', 'maximum_peers', @set_args)
    end

    def maximum_peers
      config_get('bgp_neighbor', 'maximum_peers', @get_args)
    end

    def default_maximum_peers
      config_get_default('bgp_neighbor', 'maximum_peers')
    end

    def password_set(val, type=nil)
      val = val.to_s
      if val.strip.empty?
        set_args_keys(state: 'no', type: '', passwd: '')
      elsif type.nil?
        set_args_keys(state:  '',
                      type:   Encryption.symbol_to_cli(default_password_type),
                      passwd: val.to_s)
      else
        set_args_keys(state:  '',
                      type:   Encryption.symbol_to_cli(type),
                      passwd: val.to_s)
      end
      config_set('bgp_neighbor', 'password', @set_args)
    end

    def password
      config_get('bgp_neighbor', 'password', @get_args)
    end

    def default_password
      config_get_default('bgp_neighbor', 'password')
    end

    def password_type
      result = config_get('bgp_neighbor', 'password_type', @get_args)
      Encryption.cli_to_symbol(result.to_i)
    end

    def default_password_type
      result = config_get_default('bgp_neighbor', 'password_type')
      Encryption.cli_to_symbol(result)
    end

    def remote_as=(val)
      if val == default_remote_as
        set_args_keys(state: 'no', remote_as: '')
      else
        set_args_keys(state: '', remote_as: val)
      end
      config_set('bgp_neighbor', 'remote_as', @set_args)
    end

    def remote_as
      config_get('bgp_neighbor', 'remote_as', @get_args).to_s
    end

    def default_remote_as
      config_get_default('bgp_neighbor', 'remote_as').to_s
    end

    def remove_private_as=(val)
      val = val.to_sym
      if val == default_remove_private_as
        set_args_keys(state: 'no', option: '')
      else
        set_args_keys(state:  '',
                      option: (val == :enable) ? '' : val.to_s)
      end
      config_set('bgp_neighbor', 'remove_private_as', @set_args)
    end

    def remove_private_as
      result = config_get('bgp_neighbor', 'remove_private_as', @get_args)
      return default_remove_private_as if result.nil?
      result.first.nil? ? :enable : result.first.to_sym
    end

    def default_remove_private_as
      result = config_get_default('bgp_neighbor', 'remove_private_as')
      result.to_sym
    end

    def shutdown=(val)
      set_args_keys(state: (val) ? '' : 'no')
      config_set('bgp_neighbor', 'shutdown', @set_args)
    end

    def shutdown
      result = config_get('bgp_neighbor', 'shutdown', @get_args)
      result ? true : false
    end

    def default_shutdown
      config_get_default('bgp_neighbor', 'shutdown')
    end

    def suppress_4_byte_as=(val)
      set_args_keys(state: (val) ? '' : 'no')
      config_set('bgp_neighbor', 'suppress_4_byte_as', @set_args)
    end

    def suppress_4_byte_as
      result = config_get('bgp_neighbor', 'suppress_4_byte_as', @get_args)
      result ? true : false
    end

    def default_suppress_4_byte_as
      config_get_default('bgp_neighbor', 'suppress_4_byte_as')
    end

    def timers_set(keepalive, hold)
      if keepalive == default_timers_keepalive &&
         hold == default_timers_holdtime
        set_args_keys(state: 'no', keepalive: timers_keepalive,
                      hold: timers_holdtime)
      else
        set_args_keys(state: '', keepalive: keepalive,
                      hold: hold)
      end
      config_set('bgp_neighbor', 'timers_keepalive_hold', @set_args)
    end

    def timers_keepalive_hold
      match = config_get('bgp_neighbor', 'timers_keepalive_hold', @get_args)
      match.nil? ? default_timers_keepalive_hold : match
    end

    def timers_keepalive
      keepalive, _hold = timers_keepalive_hold
      return default_timers_keepalive if keepalive.nil?
      keepalive.to_i
    end

    def timers_holdtime
      _keepalive, hold = timers_keepalive_hold
      return default_timers_holdtime if hold.nil?
      hold.to_i
    end

    def default_timers_keepalive
      config_get_default('bgp_neighbor', 'timers_keepalive')
    end

    def default_timers_holdtime
      config_get_default('bgp_neighbor', 'timers_holdtime')
    end

    def default_timers_keepalive_hold
      ["#{default_timers_keepalive}", "#{default_timers_holdtime}"]
    end

    def transport_passive_only=(val)
      set_args_keys(state: (val) ? '' : 'no')
      config_set('bgp_neighbor', 'transport_passive_only', @set_args)
    end

    def transport_passive_only
      result = config_get('bgp_neighbor', 'transport_passive_only', @get_args)
      result ? true : false
    end

    def default_transport_passive_only
      config_get_default('bgp_neighbor', 'transport_passive_only')
    end

    def update_source=(val)
      if val.strip == default_update_source
        set_args_keys(state: 'no', interface: update_source)
      else
        set_args_keys(state: '', interface: val)
      end
      config_set('bgp_neighbor', 'update_source', @set_args)
    end

    def update_source
      result = config_get('bgp_neighbor', 'update_source', @get_args)
      result.downcase.strip
    end

    def default_update_source
      config_get_default('bgp_neighbor', 'update_source')
    end
  end # class
end # module
