# BGP neighbor provider class
#
# August 2015, Jie Yang
#
# Copyright (c) 2015 Cisco and/or its affiliates.
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
require File.join(File.dirname(__FILE__), 'node')
require File.join(File.dirname(__FILE__), 'bgp')
require File.join(File.dirname(__FILE__), 'cisco_cmn_utils')

module Cisco
  class RouterBgpNeighbor
    attr_reader :nbr, :vrf, :asn

    @@node = Node.instance
    raise TypeError if @@node.nil?

    def initialize(asn, vrf, nbr, instantiate=true)
      raise TypeError unless nbr.is_a?(String)
      # for IP/prefix format, such as "1.1.1.1/24" or "2000:123:38::34/64",
      # we need to mask the address using prefix length, so that it becomes
      # something like "1.1.1.0/24" or "2000:123:38::/64"
      @nbr = RouterBgpNeighbor.nbr_munge(nbr)
      @asn = asn
      @vrf = vrf
      @get_args = @set_args = { :asnum => @asn, :nbr => @nbr, }
      @get_args[:vrf] = @set_args[:vrf] = vrf if vrf != 'default'

      create if instantiate
    end

    def RouterBgpNeighbor.neighbors
      hash = {}
      RouterBgp.routers.each {|asn, vrf|
        hash[asn] = {}
        vrf.each_key { |vrf_id|
          get_args = { :asnum => asn }
          get_args[:vrf] = vrf_id unless vrf_id == 'default'
          neighbor_list = @@node.config_get("bgp_neighbor", "all_neighbors",
                                            get_args)
          next if neighbor_list.nil?

          hash[asn][vrf_id] = {}
          neighbor_list.each {|nbr|
            hash[asn][vrf_id][nbr] = RouterBgpNeighbor.new(asn, vrf_id,
                                                           nbr, false)
          }
        }
      }
      hash
    rescue Cisco::CliError => e
      # Raise the error unless the error message contains "Syntax error", which
      # means the error was caused by feature is not enabled.
      raise unless e.clierror =~ /Syntax error/
      return {}
    end

    def RouterBgpNeighbor.nbr_munge(nbr)
      # 'nbr' supports multiple formats which can nvgen differently:
      #   1.1.1.1      nvgens 1.1.1.1
      #   1.1.1.1/16   nvgens 1.1.0.0/16
      #   200:2::20/64 nvgens 200:2::/64
      addr, mask = nbr.split('/')
      addr = IPAddr.new(nbr).to_s
      addr = addr + '/' + mask unless mask.nil?
      addr
    end

    def create
      set_args_keys(:state => "")
      @@node.config_set("bgp", "create_destroy_neighbor", @set_args)
    end

    def destroy
      set_args_keys(:state => "no")
      @@node.config_set("bgp", "create_destroy_neighbor", @set_args)
    end

    def set_args_keys_default
      keys = { :asnum => @asn, :nbr => @nbr }
      keys[:vrf] = @vrf unless @vrf == 'default'
      @set_args = keys
    end

    def set_args_keys(hash = {})
      set_args_keys_default
      @set_args = @set_args.merge!(hash) unless hash.empty?
    end

    def description=(desc)
      raise TypeError unless desc.is_a?(String)
      desc.strip!
      set_args_keys({ :state => desc.empty? ? "no" : "",
                      :desc  => desc, })
      @@node.config_set("bgp_neighbor", "description", @set_args)
    end

    def description
      desc = @@node.config_get("bgp_neighbor", "description", @get_args)
      return "" if desc.nil?
      desc.shift.strip
    end

    def default_description
      @@node.config_get_default("bgp_neighbor", "description")
    end

    def disable_connected_check=(val)
      set_args_keys(:state => (val) ? "" : "no")
      @@node.config_set("bgp_neighbor", "disable_connected_check", @set_args)
    end

    def disable_connected_check
      result = @@node.config_get("bgp_neighbor", "disable_connected_check",
                                 @get_args)
      result ? true : false
    end

    def default_disable_connected_check
      @@node.config_get_default("bgp_neighbor", "disable_connected_check")
    end

    def dont_capability_negotiate=(val)
      set_args_keys(:state => (val) ? "" : "no")
      @@node.config_set("bgp_neighbor", "dont_capability_negotiate", @set_args)
    end

    def dont_capability_negotiate
      result = @@node.config_get("bgp_neighbor", "dont_capability_negotiate",
                                 @get_args)
      result ? true : false
    end

    def default_dont_capability_negotiate
      @@node.config_get_default("bgp_neighbor", "dont_capability_negotiate")
    end

    def dynamic_capability=(val)
      set_args_keys(:state => (val) ? "" : "no")
      @@node.config_set("bgp_neighbor", "dynamic_capability", @set_args)
    end

    def dynamic_capability
      result = @@node.config_get("bgp_neighbor", "dynamic_capability",
                                 @get_args)
      result ? true : false
    end

    def default_dynamic_capability
      @@node.config_get_default("bgp_neighbor", "dynamic_capability")
    end

    def ebgp_multihop=(ttl)
      set_args_keys(:state => (ttl == default_ebgp_multihop) ? "no" : "",
                    :ttl => (ttl == default_ebgp_multihop) ? "" : ttl)
      @@node.config_set("bgp_neighbor", "ebgp_multihop", @set_args)
    end

    def ebgp_multihop
      result = @@node.config_get("bgp_neighbor", "ebgp_multihop", @get_args)
      result.nil? ? default_ebgp_multihop : result.first.to_i
    end

    def default_ebgp_multihop
      @@node.config_get_default("bgp_neighbor", "ebgp_multihop")
    end

    def local_as=(val)
      asnum = RouterBgp.process_asnum(val)
      if asnum == default_local_as
        set_args_keys(:state => "no", :local_as => "")
      else
        set_args_keys(:state => "", :local_as => val)
      end
      @@node.config_set("bgp_neighbor", "local_as", @set_args)
    end

    def local_as
      result = @@node.config_get("bgp_neighbor", "local_as", @get_args)
      return default_local_as if result.nil?
      return result.first.to_i unless /\d+\.\d+$/.match(result.first)
      result.first
    end

    def default_local_as
      @@node.config_get_default("bgp_neighbor", "local_as")
    end

    def log_neighbor_changes=(val)
      val = val.to_sym
      if val == default_log_neighbor_changes
        set_args_keys(:state => "no", :disable => "")
      else
        set_args_keys(:state =>"",
                      :disable => (val == :enable) ? "" : "disable")
      end
      @@node.config_set("bgp_neighbor", "log_neighbor_changes", @set_args)
    end

    def log_neighbor_changes
      result = @@node.config_get("bgp_neighbor", "log_neighbor_changes",
                                 @get_args)
      return default_log_neighbor_changes if result.nil?
      return :disable if /disable/.match(result.first)
      :enable
    end

    def default_log_neighbor_changes
      result = @@node.config_get_default("bgp_neighbor", "log_neighbor_changes")
      result.to_sym
    end

    def low_memory_exempt=(val)
      set_args_keys(:state => (val) ? "" : "no")
      @@node.config_set("bgp_neighbor", "low_memory_exempt", @set_args)
    end

    def low_memory_exempt
      result = @@node.config_get("bgp_neighbor", "low_memory_exempt", @get_args)
      result ? true : false
    end

    def default_low_memory_exempt
      @@node.config_get_default("bgp_neighbor", "low_memory_exempt")
    end

    def maximum_peers=(val)
      set_args_keys(:state => (val == default_maximum_peers) ? "no" : "",
                    :num => (val == default_maximum_peers) ? "" : val)
      @@node.config_set("bgp_neighbor", "maximum_peers", @set_args)
    end

    def maximum_peers
      result = @@node.config_get("bgp_neighbor", "maximum_peers", @get_args)
      result.nil? ? default_maximum_peers : result.first.to_i
    end

    def default_maximum_peers
      @@node.config_get_default("bgp_neighbor", "maximum_peers")
    end

    def password=(val)
      val = val.to_s
      if val.strip.empty?
        set_args_keys(:state => "no", :type =>"", :passwd => "")
      else
        set_args_keys(:state => "",
                      :type => @password_type.nil? ?
                               Encryption.symbol_to_cli(password_type)
                               : @password_type,
                      :passwd => val.to_s)
      end
      @@node.config_set("bgp_neighbor", "password", @set_args)
    end

    def password
      result = @@node.config_get("bgp_neighbor", "password", @get_args)
      result.nil? ? "" : result.first.to_s
    end

    def default_password
      @@node.config_get_default("bgp_neighbor", "password")
    end

    def password_type=(val)
      @password_type = Cisco::Encryption.symbol_to_cli(val)
    end

    def password_type
      result = @@node.config_get("bgp_neighbor", "password_type", @get_args)
      if result.nil?
        result = default_password_type
      else
        result = result.first.to_i
      end
      Encryption.cli_to_symbol(result)
    end

    def default_password_type
      @@node.config_get_default("bgp_neighbor", "password_type")
    end

    def remote_as=(val)
      asnum = RouterBgp.process_asnum(val)
      if asnum == default_remote_as
        set_args_keys(:state => "no", :remote_as => "")
      else
        set_args_keys(:state => "", :remote_as => val)
      end
      @@node.config_set("bgp_neighbor", "remote_as", @set_args)
    end

    def remote_as
      result = @@node.config_get("bgp_neighbor", "remote_as", @get_args)
      return default_remote_as if result.nil?
      return result.first.to_i unless /\d+\.\d+$/.match(result.first)
      result.first
    end

    def default_remote_as
      @@node.config_get_default("bgp_neighbor", "remote_as")
    end

    def remove_private_as=(val)
      val = val.to_sym
      if val == default_remove_private_as
        set_args_keys(:state => "no", :option => "")
      else
        set_args_keys(:state => "",
                      :option => (val == :enable) ? "" : val.to_s)
      end
      @@node.config_set("bgp_neighbor", "remove_private_as", @set_args)
    end

    def remove_private_as
      result = @@node.config_get("bgp_neighbor", "remove_private_as", @get_args)
      return default_remove_private_as if result.nil?
      result.first.nil? ? :enable : result.first.to_sym
    end

    def default_remove_private_as
      result = @@node.config_get_default("bgp_neighbor", "remove_private_as")
      result.to_sym
    end

    def shutdown=(val)
      set_args_keys(:state => (val) ? "" : "no")
      @@node.config_set("bgp_neighbor", "shutdown", @set_args)
    end

    def shutdown
      result = @@node.config_get("bgp_neighbor", "shutdown", @get_args)
      result ? true : false
    end

    def default_shutdown
      @@node.config_get_default("bgp_neighbor", "shutdown")
    end

    def suppress_4_byte_as=(val)
      set_args_keys(:state => (val) ? "" : "no")
      @@node.config_set("bgp_neighbor", "suppress_4_byte_as", @set_args)
    end

    def suppress_4_byte_as
      result = @@node.config_get("bgp_neighbor", "suppress_4_byte_as",
                                 @get_args)
      result ? true : false
    end

    def default_suppress_4_byte_as
      @@node.config_get_default("bgp_neighbor", "suppress_4_byte_as")
    end

    def timers_set(keepalive, hold)
      if keepalive == default_timers_keepalive and
         hold == default_timers_holdtime
        set_args_keys(:state => "no", :keepalive => timers_keepalive,
                      :hold => timers_holdtime)
      else
        set_args_keys(:state =>"", :keepalive => keepalive,
                      :hold => hold)
      end
      @@node.config_set("bgp_neighbor", "timers_keepalive_hold", @set_args)
    end

    def timers_keepalive_hold
      match = @@node.config_get("bgp_neighbor", "timers_keepalive_hold",
                                @get_args)
      match.nil? ? default_timers_keepalive_hold : match.first
    end

    def timers_keepalive
      keepalive, hold = timers_keepalive_hold
      return default_timers_keepalive if keepalive.nil?
      keepalive.to_i
    end

    def timers_holdtime
      keepalive, hold = timers_keepalive_hold
      return default_timers_holdtime if hold.nil?
      hold.to_i
    end

    def default_timers_keepalive
      @@node.config_get_default("bgp_neighbor", "timers_keepalive")
    end

    def default_timers_holdtime
      @@node.config_get_default("bgp_neighbor", "timers_holdtime")
    end

    def default_timers_keepalive_hold
      values = ["#{default_timers_keepalive}",
                "#{default_timers_holdtime}"]
    end

    def transport_passive_only=(val)
      set_args_keys(:state => (val) ? "" : "no")
      @@node.config_set("bgp_neighbor", "transport_passive_only", @set_args)
    end

    def transport_passive_only
      result = @@node.config_get("bgp_neighbor", "transport_passive_only",
                                 @get_args)
      result ? true : false
    end

    def default_transport_passive_only
      @@node.config_get_default("bgp_neighbor", "transport_passive_only")
    end

    def update_source=(val)
      if val.strip == default_update_source
        set_args_keys(:state => "no", :interface => update_source)
      else
        set_args_keys(:state => "", :interface => val)
      end
      @@node.config_set("bgp_neighbor", "update_source", @set_args)
    end

    def update_source
      result = @@node.config_get("bgp_neighbor", "update_source", @get_args)
      return default_update_source if result.nil? or result.first.nil?
      result.first.downcase.strip
    end

    def default_update_source
      @@node.config_get_default("bgp_neighbor", "update_source")
    end
  end # class
end # module
