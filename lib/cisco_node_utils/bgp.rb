# June 2015, Michael G Wiebe
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

require_relative 'cisco_cmn_utils'
require_relative 'node_util'
require_relative 'feature'
require_relative 'logger'

module Cisco
  # RouterBgp - node utility class for BGP general config management
  class RouterBgp < NodeUtil
    attr_reader :asnum, :vrf

    def initialize(asnum, vrf='default', instantiate=true)
      fail ArgumentError unless vrf.is_a? String
      fail ArgumentError unless vrf.length > 0
      @asnum = RouterBgp.validate_asnum(asnum)
      @vrf = vrf
      set_args_keys_default
      create if instantiate
    end

    def to_s
      "BGP #{asnum} VRF '#{vrf}'"
    end

    # Create a hash of all router bgp default and non-default
    # vrf instances
    def self.routers
      asnum = config_get('bgp', 'router')
      return {} if asnum.nil?

      hash_final = {}
      asnum = asnum.to_i unless /\d+.\d+/.match(asnum)
      hash_tmp = {
        asnum => { 'default' => RouterBgp.new(asnum, 'default', false) }
      }
      vrf_ids = config_get('bgp', 'vrf', asnum: asnum)
      unless vrf_ids.nil?
        vrf_ids.each do |vrf|
          hash_tmp[asnum][vrf] = RouterBgp.new(asnum, vrf, false)
        end
      end
      hash_final.merge!(hash_tmp)
      return hash_final
    rescue Cisco::CliError => e
      # cmd will syntax reject when feature is not enabled
      raise unless e.clierror =~ /Syntax error/
      return {}
    end

    def self.validate_asnum(asnum)
      err_msg = 'BGP asnum must be type String or Integer'
      fail ArgumentError, err_msg unless asnum.is_a?(Integer) ||
                                         asnum.is_a?(String)
      if asnum.is_a? String
        # Match ASDOT '1.5' or ASPLAIN '55' strings
        fail ArgumentError unless /^(\d+|\d+\.\d+)$/.match(asnum)
      end
      asnum.to_s
    end

    def router_bgp(state='')
      @set_args[:state] = state
      if vrf == 'default'
        config_set('bgp', 'router', @set_args)
      else
        config_set('bgp', 'vrf', @set_args)
      end
      set_args_keys_default
    end

    # Create one router bgp instance
    def create
      Feature.bgp_enable if platform == :nexus
      router_bgp
      wait_for_process_initialized
    end

    # Destroy router bgp instance
    def destroy
      router_bgp('no')
    end

    def process_initialized?
      config_get('bgp', 'process_initialized')
    end

    def wait_for_process_initialized
      return unless node.product_id[/N(5|6|8)/]

      # Hack for slow-start platforms which will have setter failures if the
      # bgp instance is still initializing. To see this problem in a sandbox
      # do 'router bgp 1 ; router bgp 1 ; shutdown'.
      4.times do
        return if process_initialized?
        sleep 1
        node.cache_flush
      end
      fail 'BGP process is not initialized yet'
    end

    # Helper method to delete @set_args hash keys
    def set_args_keys_default
      @set_args = { asnum: @asnum }
      @set_args[:vrf] = @vrf unless @vrf == 'default'
      @get_args = @set_args
    end

    # Attributes:

    # nsr Getter
    def nsr
      return nil if platform == :ios_xr && @vrf != 'default'
      config_get('bgp', 'nsr', @get_args)
    end

    # Bestpath Getters
    def bestpath_always_compare_med
      config_get('bgp', 'bestpath_always_compare_med', @get_args)
    end

    def bestpath_aspath_multipath_relax
      config_get('bgp', 'bestpath_aspath_multipath_relax', @get_args)
    end

    def bestpath_compare_routerid
      config_get('bgp', 'bestpath_compare_routerid', @get_args)
    end

    def bestpath_cost_community_ignore
      config_get('bgp', 'bestpath_cost_community_ignore', @get_args)
    end

    def bestpath_med_confed
      return nil if platform == :ios_xr && @vrf != 'default'
      config_get('bgp', 'bestpath_med_confed', @get_args)
    end

    def bestpath_med_missing_as_worst
      config_get('bgp', 'bestpath_med_missing_as_worst', @get_args)
    end

    def bestpath_med_non_deterministic
      config_get('bgp', 'bestpath_med_non_deterministic', @get_args)
    end

    # nsr Setter
    def nsr=(enable)
      if platform == :ios_xr && @vrf != 'default'
        fail Cisco::UnsupportedError.new('bgp', 'nsr', 'set', 'nsr is not ' \
                  'configurable on a per-VRF basis on ios_xr')
      end
      @set_args[:state] = (enable ? '' : 'no')
      config_set('bgp', 'nsr', @set_args)
      set_args_keys_default
    end

    # Bestpath Setters
    def bestpath_always_compare_med=(enable)
      @set_args[:state] = (enable ? '' : 'no')
      config_set('bgp', 'bestpath_always_compare_med', @set_args)
      set_args_keys_default
    end

    def bestpath_aspath_multipath_relax=(enable)
      @set_args[:state] = (enable ? '' : 'no')
      config_set('bgp', 'bestpath_aspath_multipath_relax', @set_args)
      set_args_keys_default
    end

    def bestpath_compare_routerid=(enable)
      @set_args[:state] = (enable ? '' : 'no')
      config_set('bgp', 'bestpath_compare_routerid', @set_args)
      set_args_keys_default
    end

    def bestpath_cost_community_ignore=(enable)
      @set_args[:state] = (enable ? '' : 'no')
      config_set('bgp', 'bestpath_cost_community_ignore', @set_args)
      set_args_keys_default
    end

    def bestpath_med_confed=(enable)
      if platform == :ios_xr && @vrf != 'default'
        fail Cisco::UnsupportedError.new('bgp', 'bestpath_med_confed', 'set',
                                         'bestpath_med_confed is not ' \
                                         'configurable on a per-VRF basis ' \
                                         'on IOS XR')
      end
      @set_args[:state] = (enable ? '' : 'no')
      config_set('bgp', 'bestpath_med_confed', @set_args)
      set_args_keys_default
    end

    def bestpath_med_missing_as_worst=(enable)
      @set_args[:state] = (enable ? '' : 'no')
      config_set('bgp', 'bestpath_med_missing_as_worst', @set_args)
      set_args_keys_default
    end

    def bestpath_med_non_deterministic=(enable)
      @set_args[:state] = (enable ? '' : 'no')
      config_set('bgp', 'bestpath_med_non_deterministic', @set_args)
      set_args_keys_default
    end

    # nsr Default
    def default_nsr
      return nil if platform == :ios_xr && @vrf != 'default'
      config_get_default('bgp', 'nsr')
    end

    # Bestpath Defaults
    def default_bestpath_always_compare_med
      config_get_default('bgp', 'bestpath_always_compare_med')
    end

    def default_bestpath_aspath_multipath_relax
      config_get_default('bgp', 'bestpath_aspath_multipath_relax')
    end

    def default_bestpath_compare_routerid
      config_get_default('bgp', 'bestpath_compare_routerid')
    end

    def default_bestpath_cost_community_ignore
      config_get_default('bgp', 'bestpath_cost_community_ignore')
    end

    def default_bestpath_med_confed
      return nil if platform == :ios_xr && @vrf != 'default'
      config_get_default('bgp', 'bestpath_med_confed')
    end

    def default_bestpath_med_missing_as_worst
      config_get_default('bgp', 'bestpath_med_missing_as_worst')
    end

    def default_bestpath_med_non_deterministic
      config_get_default('bgp', 'bestpath_med_non_deterministic')
    end

    # Cluster Id (Getter/Setter/Default)
    def cluster_id
      return nil if platform == :ios_xr && @vrf != 'default'
      config_get('bgp', 'cluster_id', @get_args)
    end

    def cluster_id=(id)
      # In order to remove a bgp cluster_id you cannot simply issue
      # 'no bgp cluster-id'.  IMO this should be possible because you
      # can only configure a single bgp cluster-id.
      if platform == :ios_xr && @vrf != 'default'
        fail Cisco::UnsupportedError.new('bgp', 'cluster_id', 'set',
                                         'cluster-id is not configurable ' \
                                         'on a per-VRF basis on IOS XR')
      end
      # HACK: specify a dummy id when removing the property.
      dummy_id = 1
      if id == default_cluster_id
        @set_args[:state] = 'no'
        @set_args[:id] = dummy_id
      else
        @set_args[:state] = ''
        @set_args[:id] = id
      end
      config_set('bgp', 'cluster_id', @set_args)
      set_args_keys_default
    end

    def default_cluster_id
      return nil if platform == :ios_xr && @vrf != 'default'
      config_get_default('bgp', 'cluster_id')
    end

    # Confederation Id (Getter/Setter/Default)
    def confederation_id
      return nil if platform == :ios_xr && @vrf != 'default'
      config_get('bgp', 'confederation_id', @get_args)
    end

    def confederation_id=(id)
      # In order to remove a bgp confed id you cannot simply issue
      # 'no bgp confederation id'.  IMO this should be possible
      # because you can only configure a single bgp confed id.
      if platform == :ios_xr && @vrf != 'default'
        fail Cisco::UnsupportedError.new('bgp', 'confederation_id', 'set',
                                         'confederation-id is not ' \
                                         'configurable ' \
                                         'on a per-VRF basis on IOS XR')
      end
      # HACK: specify a dummy id when removing the property.
      dummy_id = 1
      if id == default_confederation_id
        @set_args[:state] = 'no'
        @set_args[:id] = dummy_id
      else
        @set_args[:state] = ''
        @set_args[:id] = id
      end
      config_set('bgp', 'confederation_id', @set_args)
      set_args_keys_default
    end

    def default_confederation_id
      return nil if platform == :ios_xr && @vrf != 'default'
      config_get_default('bgp', 'confederation_id')
    end

    #
    # disable-policy-batching (Getter/Setter/Default)
    #
    def disable_policy_batching
      config_get('bgp', 'disable_policy_batching', @get_args)
    end

    def disable_policy_batching=(enable)
      @set_args[:state] = (enable ? '' : 'no')
      config_set('bgp', 'disable_policy_batching', @set_args)
      set_args_keys_default
    end

    def default_disable_policy_batching
      config_get_default('bgp', 'disable_policy_batching')
    end

    #
    # disable-policy-batching ipv4 prefix-list <prefix_list>
    #
    def disable_policy_batching_ipv4
      config_get('bgp', 'disable_policy_batching_ipv4', @get_args)
    end

    def disable_policy_batching_ipv4=(prefix_list)
      dummy_prefixlist = 'x'
      if prefix_list == default_disable_policy_batching_ipv4
        @set_args[:state] = 'no'
        @set_args[:prefix_list] = dummy_prefixlist
      else
        @set_args[:state] = ''
        @set_args[:prefix_list] = prefix_list
      end
      config_set('bgp', 'disable_policy_batching_ipv4', @set_args)
      set_args_keys_default
    end

    def default_disable_policy_batching_ipv4
      config_get_default('bgp', 'disable_policy_batching_ipv4')
    end

    #
    # disable-policy-batching ipv6 prefix-list <prefix_list>
    #
    def disable_policy_batching_ipv6
      config_get('bgp', 'disable_policy_batching_ipv6', @get_args)
    end

    def disable_policy_batching_ipv6=(prefix_list)
      dummy_prefixlist = 'x'
      if prefix_list == default_disable_policy_batching_ipv6
        @set_args[:state] = 'no'
        @set_args[:prefix_list] = dummy_prefixlist
      else
        @set_args[:state] = ''
        @set_args[:prefix_list] = prefix_list
      end
      config_set('bgp', 'disable_policy_batching_ipv6', @set_args)
      set_args_keys_default
    end

    def default_disable_policy_batching_ipv6
      config_get_default('bgp', 'disable_policy_batching_ipv6')
    end

    # Enforce First As (Getter/Setter/Default)
    def enforce_first_as
      config_get('bgp', 'enforce_first_as', @get_args)
    end

    def enforce_first_as=(enable)
      # TODO: write a helper method for this repeated logic
      # enforce_first_as is on by default (=>true)
      # XR=>true  = enable enforce_first_as  = 'no bgp enforce-first-as disable'
      # XR=>false = disable enforce_first_as = 'bgp enforce-first-as disable'
      # Nexus nvgens the 'no' command.
      # Nexus=>true  = enable enforce_first_as  = 'enforce-first-as'
      # Nexus=>false = disable enforce_first_as = 'no enforce-first-as'
      enable = !enable if platform == :ios_xr
      @set_args[:state] = (enable ? '' : 'no')
      config_set('bgp', 'enforce_first_as', @set_args)
      set_args_keys_default
    end

    def default_enforce_first_as
      config_get_default('bgp', 'enforce_first_as')
    end

    # event-history
    # event-history cli [ size <size> ]
    # Nvgen as True With optional 'size <size>
    def event_history_cli
      match = config_get('bgp', 'event_history_cli', @get_args)
      if match.is_a?(Array)
        return 'false' if match[0] == 'no '
        if match[1]
          return match[1] if match[1][/\A\d+\z/]
          return 'size_' + match[1]
        end
      end
      default_event_history_cli
    end

    def event_history_cli=(val)
      size = val[/small|medium|large|disable|\A\d+\z/]
      @set_args[:size] = size.nil? ? '' : "size #{size}"
      @set_args[:state] = val[/false/] ? 'no' : ''
      config_set('bgp', 'event_history_cli', @set_args)
      set_args_keys_default
    end

    def default_event_history_cli
      config_get_default('bgp', 'event_history_cli')
    end

    # event-history detail [ size <size> ]
    # Nvgen as True With optional 'size <size>
    def event_history_detail
      match = config_get('bgp', 'event_history_detail', @get_args)
      if match.is_a?(Array)
        return 'false' if match[0] == 'no '
        if match[1]
          return match[1] if match[1][/\A\d+\z/]
          return 'size_' + match[1]
        end
        return 'true'
      end
      default_event_history_detail
    end

    def event_history_detail=(val)
      size = val[/small|medium|large|disable|\A\d+\z/]
      @set_args[:size] = size.nil? ? '' : "size #{size}"
      @set_args[:state] = val[/false/] ? 'no' : ''
      config_set('bgp', 'event_history_detail', @set_args)
      set_args_keys_default
    end

    def default_event_history_detail
      config_get_default('bgp', 'event_history_detail')
    end

    # event-history errors [ size <size> ]
    # Nvgen as True With optional 'size <size>
    def event_history_errors
      match = config_get('bgp', 'event_history_errors', @get_args)
      if match.is_a?(Array)
        return 'false' if match[0] == 'no '
        if match[1]
          return match[1] if match[1][/\A\d+\z/]
          return 'size_' + match[1]
        end
      end
      default_event_history_errors
    end

    def event_history_errors=(val)
      size = val[/small|medium|large|disable|\A\d+\z/]
      @set_args[:size] = size.nil? ? '' : "size #{size}"
      @set_args[:state] = val[/false/] ? 'no' : ''
      config_set('bgp', 'event_history_errors', @set_args)
      set_args_keys_default
    end

    def default_event_history_errors
      config_get_default('bgp', 'event_history_errors')
    end

    # event-history events [ size <size> ]
    # Nvgen as True With optional 'size <size>
    def event_history_events
      match = config_get('bgp', 'event_history_events', @get_args)
      if match.is_a?(Array)
        return 'false' if match[0] == 'no '
        if match[1]
          return match[1] if match[1][/\A\d+\z/]
          return 'size_' + match[1]
        end
      end
      default_event_history_events
    end

    def event_history_events=(val)
      size = val[/small|medium|large|disable|\A\d+\z/]
      @set_args[:size] = size.nil? ? '' : "size #{size}"
      @set_args[:state] = val[/false/] ? 'no' : ''
      config_set('bgp', 'event_history_events', @set_args)
      set_args_keys_default
    end

    def default_event_history_events
      if Utils.image_version?(/7.0.3.I2|I3|I4/) ||
         node.product_id[/(N5|N6|N7|N9.*-F)/]
        config_get_default('bgp', 'event_history_events')
      else
        config_get('bgp', 'event_history_events_bytes', @get_args)
      end
    end

    # event-history objstore [ size <size> ]
    # Nvgen as True With optional 'size <size>
    def event_history_objstore
      match = config_get('bgp', 'event_history_objstore', @get_args)
      if match.is_a?(Array)
        return 'false' if match[0] == 'no '
        if match[1]
          return match[1] if match[1][/\A\d+\z/]
          return 'size_' + match[1]
        end
        return 'true'
      end
      default_event_history_objstore
    end

    def event_history_objstore=(val)
      size = val[/small|medium|large|disable|\A\d+\z/]
      @set_args[:size] = size.nil? ? '' : "size #{size}"
      @set_args[:state] = val[/false/] ? 'no' : ''
      config_set('bgp', 'event_history_objstore', @set_args)
      set_args_keys_default
    end

    def default_event_history_objstore
      config_get_default('bgp', 'event_history_objstore')
    end

    # event-history periodic [ size <size> ]
    # Nvgen as True With optional 'size <size>
    def event_history_periodic
      match = config_get('bgp', 'event_history_periodic', @get_args)
      if match.is_a?(Array)
        return 'false' if match[0] == 'no '
        if match[1]
          return match[1] if match[1][/\A\d+\z/]
          return 'size_' + match[1]
        end
      else
        return default_event_history_periodic
      end
      return 'true' unless default_event_history_periodic[/size/]
      default_event_history_periodic
    end

    def event_history_periodic=(val)
      size = val[/small|medium|large|disable|\A\d+\z/] unless val[/false|true/]
      @set_args[:size] = size.nil? ? '' : "size #{size}"
      @set_args[:state] = val[/false/] ? 'no' : ''
      config_set('bgp', 'event_history_periodic', @set_args)
      set_args_keys_default
    end

    def default_event_history_periodic
      if Utils.image_version?(/7.0.3.I2|I3|I4/) ||
         node.product_id[/(N5|N6|N7|N9.*-F)/]
        config_get_default('bgp', 'event_history_periodic')
      else
        config_get('bgp', 'event_history_periodic_bytes', @get_args)
      end
    end

    # Fast External fallover (Getter/Setter/Default)
    def fast_external_fallover
      config_get('bgp', 'fast_external_fallover', @get_args)
    end

    def fast_external_fallover=(enable)
      # TODO: write a helper method for this repeated logic
      # fast_external_fallover is on by default (=>true)
      # XR=>true  = 'no bgp fast-external-fallover disable'
      # XR=>false = 'bgp fast-external-fallover disable'
      # Nexus nvgens the 'no' command.
      # Nexus=>true  = 'fast-external-fallover'
      # Nexus=>false = 'no fast-external-fallover'
      enable = !enable if platform == :ios_xr
      @set_args[:state] = (enable ? '' : 'no')
      config_set('bgp', 'fast_external_fallover', @set_args)
      set_args_keys_default
    end

    def default_fast_external_fallover
      config_get_default('bgp', 'fast_external_fallover')
    end

    # Flush Routes (Getter/Setter/Default)
    def flush_routes
      config_get('bgp', 'flush_routes', @get_args)
    end

    def flush_routes=(enable)
      @set_args[:state] = (enable ? '' : 'no')
      config_set('bgp', 'flush_routes', @set_args)
      set_args_keys_default
    end

    def default_flush_routes
      config_get_default('bgp', 'flush_routes')
    end

    # Confederation Peers (Getter/Setter/Default)
    def confederation_peers
      # NX: confederation peers is retrieved as a string '1 2 3'
      # XR: retrieved as an array.
      # So make it an array in the NX case.
      # Sort the end results to make it consistent across both platforms.
      return nil if platform == :ios_xr && @vrf != 'default'
      peers = config_get('bgp', 'confederation_peers', @get_args)
      peers = peers.split(' ') if peers.is_a?(String)
      peers.sort
    end

    def confederation_peers=(should)
      # confederation peers are additive. So create a delta hash of entries
      # and only apply the changes
      if platform == :ios_xr && @vrf != 'default'
        fail Cisco::UnsupportedError.new('bgp', 'confederation_peers', 'set',
                                         'confederation-peers is not ' \
                                         'configurable ' \
                                         'on a per-VRF basis on IOS XR')
      end
      should = should.flatten
      is = confederation_peers

      delta_hash = Utils.delta_add_remove(should, is)
      return if delta_hash.values.flatten.empty?
      [:add, :remove].each do |action|
        Cisco::Logger.debug('confederation_peers delta ' \
                            "#{@get_args}\n #{action}: " \
                            "#{delta_hash[action]}")
        delta_hash[action].each do |peer|
          state = (action == :add) ? '' : 'no'
          @set_args[:state] = state
          @set_args[:peer] = peer

          config_set('bgp', 'confederation_peers', @set_args)
        end
      end
    end

    def default_confederation_peers
      return nil if platform == :ios_xr && @vrf != 'default'
      config_get_default('bgp', 'confederation_peers')
    end

    # Graceful Restart Getters
    def graceful_restart
      return nil if platform == :ios_xr && @vrf != 'default'
      config_get('bgp', 'graceful_restart', @get_args)
    end

    def graceful_restart_timers_restart
      return nil if platform == :ios_xr && @vrf != 'default'
      config_get('bgp', 'graceful_restart_timers_restart', @get_args)
    end

    def graceful_restart_timers_stalepath_time
      return nil if platform == :ios_xr && @vrf != 'default'
      config_get('bgp', 'graceful_restart_timers_stalepath_time', @get_args)
    end

    def graceful_restart_helper
      return nil if platform == :ios_xr && @vrf != 'default'
      config_get('bgp', 'graceful_restart_helper', @get_args)
    end

    # Graceful Restart Setters
    def graceful_restart=(enable)
      if platform == :ios_xr && @vrf != 'default'
        fail Cisco::UnsupportedError.new('bgp', 'graceful_restart', 'set',
                                         'graceful_restart is not ' \
                                         'configurable ' \
                                         'on a per-VRF basis on IOS XR')
      end
      @set_args[:state] = (enable ? '' : 'no')
      config_set('bgp', 'graceful_restart', @set_args)
      set_args_keys_default
    end

    def graceful_restart_timers_restart=(seconds)
      if platform == :ios_xr && @vrf != 'default'
        fail Cisco::UnsupportedError.new('bgp',
                                         'graceful_restart_timers_restart',
                                         'set',
                                         'graceful_restart_timers_restart is ' \
                                         'not configurable ' \
                                         'on a per-VRF basis on IOS XR')
      end
      if seconds == default_graceful_restart_timers_restart
        @set_args[:state] = 'no'
        @set_args[:seconds] = ''
      else
        @set_args[:state] = ''
        @set_args[:seconds] = seconds
      end
      config_set('bgp', 'graceful_restart_timers_restart', @set_args)
      set_args_keys_default
    end

    def graceful_restart_timers_stalepath_time=(seconds)
      if platform == :ios_xr && @vrf != 'default'
        fail Cisco::UnsupportedError.new('bgp',
                                         'graceful_restart_timers_' \
                                         'stalepath_time', 'set',
                                         'graceful_restart_timers_' \
                                         'stalepath_time is not configurable ' \
                                         'on a per-VRF basis on IOS XR')
      end
      if seconds == default_graceful_restart_timers_stalepath_time
        @set_args[:state] = 'no'
        @set_args[:seconds] = ''
      else
        @set_args[:state] = ''
        @set_args[:seconds] = seconds
      end
      config_set('bgp', 'graceful_restart_timers_stalepath_time', @set_args)
      set_args_keys_default
    end

    def graceful_restart_helper=(enable)
      if platform == :ios_xr && @vrf != 'default'
        fail Cisco::UnsupportedError.new('bgp',
                                         'graceful_restart_helper', 'set',
                                         'graceful_restart_helper ' \
                                         'is not configurable ' \
                                         'on a per-VRF basis on IOS XR')
      end
      @set_args[:state] = (enable ? '' : 'no')
      config_set('bgp', 'graceful_restart_helper', @set_args)
      set_args_keys_default
    end

    # Graceful Restart Defaults
    def default_graceful_restart
      return nil if platform == :ios_xr && @vrf != 'default'
      config_get_default('bgp', 'graceful_restart')
    end

    def default_graceful_restart_timers_restart
      return nil if platform == :ios_xr && @vrf != 'default'
      config_get_default('bgp', 'graceful_restart_timers_restart')
    end

    def default_graceful_restart_timers_stalepath_time
      return nil if platform == :ios_xr && @vrf != 'default'
      config_get_default('bgp', 'graceful_restart_timers_stalepath_time')
    end

    def default_graceful_restart_helper
      return nil if platform == :ios_xr && @vrf != 'default'
      config_get_default('bgp', 'graceful_restart_helper')
    end

    # Isolate (Getter/Setter/Default)
    def isolate
      config_get('bgp', 'isolate', @get_args)
    end

    def isolate=(enable)
      @set_args[:state] = (enable ? '' : 'no')
      config_set('bgp', 'isolate', @set_args)
      set_args_keys_default
    end

    def default_isolate
      config_get_default('bgp', 'isolate')
    end

    # MaxAs Limit (Getter/Setter/Default)
    def maxas_limit
      config_get('bgp', 'maxas_limit', @get_args)
    end

    def maxas_limit=(limit)
      if limit == default_maxas_limit
        @set_args[:state] = 'no'
        @set_args[:limit] = ''
      else
        @set_args[:state] = ''
        @set_args[:limit] = limit
      end
      config_set('bgp', 'maxas_limit', @set_args)
      set_args_keys_default
    end

    def default_maxas_limit
      config_get_default('bgp', 'maxas_limit')
    end

    # Log Neighbor Changes (Getter/Setter/Default)
    def log_neighbor_changes
      config_get('bgp', 'log_neighbor_changes', @get_args)
    end

    def log_neighbor_changes=(enable)
      # XR logging is on by default (=>true)
      # XR=>true  = enable logging  = 'no bgp log neighbor changes disable'
      # XR=>false = disable logging = 'bgp log neighbor changes disable'
      # Nexus logging is off by default (=>false)
      # Nexus=>true  = enable logging  = 'log-neighbor-changes'
      # Nexus=>false = disable logging = 'no log-neighbor-changes'
      enable = !enable if platform == :ios_xr
      @set_args[:state] = (enable ? '' : 'no')
      config_set('bgp', 'log_neighbor_changes', @set_args)
      set_args_keys_default
    end

    def default_log_neighbor_changes
      config_get_default('bgp', 'log_neighbor_changes')
    end

    # Neighbor down fib accelerate (Getter/Setter/Default)
    def neighbor_down_fib_accelerate
      config_get('bgp', 'neighbor_down_fib_accelerate', @get_args)
    end

    def neighbor_down_fib_accelerate=(enable)
      @set_args[:state] = (enable ? '' : 'no')
      config_set('bgp', 'neighbor_down_fib_accelerate', @set_args)
      set_args_keys_default
    end

    def default_neighbor_down_fib_accelerate
      config_get_default('bgp', 'neighbor_down_fib_accelerate')
    end

    # Reconnect Interval (Getter/Setter/Default)
    def reconnect_interval
      config_get('bgp', 'reconnect_interval', @get_args)
    end

    def reconnect_interval=(seconds)
      if seconds == default_reconnect_interval
        @set_args[:state] = 'no'
        @set_args[:seconds] = ''
      else
        @set_args[:state] = ''
        @set_args[:seconds] = seconds
      end
      config_set('bgp', 'reconnect_interval', @set_args)
      set_args_keys_default
    end

    def default_reconnect_interval
      config_get_default('bgp', 'reconnect_interval')
    end

    # route_distinguisher
    # Note that this property is supported by both bgp and vrf providers.
    def route_distinguisher
      return nil if @vrf.nil? || @vrf == 'default'
      config_get('bgp', 'route_distinguisher', @get_args)
    end

    def route_distinguisher=(rd)
      if @vrf.nil? || @vrf == 'default'
        fail Cisco::UnsupportedError.new('bgp', 'route_distinguisher', 'set',
                                         'route_distinguisher is not ' \
                                         'configurable on a default VRF')
      end

      # N3k I2 images require 'nv overlay evpn' for rd and also require
      # explicit values when removing the rd command. These restrictions are
      # not not needed in I3 and newer images.
      Feature.nv_overlay_evpn_enable if
        Utils.nexus_i2_image || node.product_id[/N7/]

      if rd == default_route_distinguisher
        return if route_distinguisher.empty?
        @set_args[:state] = 'no'
        @set_args[:rd] = route_distinguisher
      else
        @set_args[:state] = ''
        @set_args[:rd] = rd
      end
      config_set('bgp', 'route_distinguisher', @set_args)
      set_args_keys_default
    end

    def default_route_distinguisher
      return nil if @vrf.nil? || @vrf == 'default'
      config_get_default('bgp', 'route_distinguisher')
    end

    # Router ID (Getter/Setter/Default)
    def router_id
      config_get('bgp', 'router_id', @get_args)
    end

    def router_id=(id)
      # In order to remove a bgp router-id you cannot simply issue
      # 'no bgp router-id'. On some platforms you can specify a dummy
      # value, but on N7K at least you need the current router_id.
      if id == default_router_id
        # Nothing to do if router_id is already set to default.
        return if router_id == default_router_id
        @set_args[:state] = 'no'
        @set_args[:id] = router_id
      else
        @set_args[:state] = ''
        @set_args[:id] = id
      end
      config_set('bgp', 'router_id', @set_args)
      set_args_keys_default
    end

    def default_router_id
      config_get_default('bgp', 'router_id')
    end

    # Shutdown (Getter/Setter/Default)
    def shutdown
      config_get('bgp', 'shutdown', @asnum)
    end

    def shutdown=(enable)
      @set_args[:state] = (enable ? '' : 'no')
      config_set('bgp', 'shutdown', @set_args)
      set_args_keys_default
    end

    def default_shutdown
      config_get_default('bgp', 'shutdown')
    end

    # Supress Fib Pending (Getter/Setter/Default)
    def suppress_fib_pending
      val = config_get('bgp', 'suppress_fib_pending', @get_args)
      val.nil? ? false : val
    end

    def suppress_fib_pending=(enable)
      enable == true ? @set_args[:state] = '' : @set_args[:state] = 'no'
      config_set('bgp', 'suppress_fib_pending', @set_args)
      set_args_keys_default
    end

    def default_suppress_fib_pending
      config_get_default('bgp', 'suppress_fib_pending')
    end

    # BGP Timers Getters
    def timer_bgp_keepalive_hold
      match = config_get('bgp', 'timer_bgp_keepalive_hold', @get_args)
      match.nil? ? default_timer_bgp_keepalive_hold : match
    end

    def timer_bgp_keepalive
      keepalive, _hold = timer_bgp_keepalive_hold
      return default_timer_bgp_keepalive if keepalive.nil?
      keepalive.to_i
    end

    def timer_bgp_holdtime
      _keepalive, hold = timer_bgp_keepalive_hold
      return default_timer_bgp_holdtime if hold.nil?
      hold.to_i
    end

    def timer_bestpath_limit
      config_get('bgp', 'timer_bestpath_limit', @get_args)
    end

    def timer_bestpath_limit_always
      config_get('bgp', 'timer_bestpath_limit_always', @get_args)
    end

    # BGP Timers Setters
    def timer_bgp_keepalive_hold_set(keepalive, hold)
      if keepalive == default_timer_bgp_keepalive &&
         hold == default_timer_bgp_holdtime
        @set_args[:state] = 'no'
        @set_args[:keepalive] = keepalive
        @set_args[:hold] = hold
      else
        @set_args[:state] = ''
        @set_args[:keepalive] = keepalive
        @set_args[:hold] = hold
      end
      config_set('bgp', 'timer_bgp_keepalive_hold', @set_args)
      set_args_keys_default
    end

    def timer_bestpath_limit_set(seconds, always=false)
      if always
        opt = 'timer_bestpath_limit_always'
      else
        opt = 'timer_bestpath_limit'
      end
      if seconds == default_timer_bestpath_limit
        @set_args[:state] = 'no'
        @set_args[:seconds] = ''
      else
        @set_args[:state] = ''
        @set_args[:seconds] = seconds
      end
      config_set('bgp', opt, @set_args)
      set_args_keys_default
    end

    # BGP Timers Defaults
    def default_timer_bgp_keepalive_hold
      ["#{default_timer_bgp_keepalive}", "#{default_timer_bgp_holdtime}"]
    end

    def default_timer_bgp_keepalive
      config_get_default('bgp', 'timer_bgp_keepalive')
    end

    def default_timer_bgp_holdtime
      config_get_default('bgp', 'timer_bgp_hold')
    end

    def default_timer_bestpath_limit
      return nil if platform == :ios_xr && @vrf != 'default'
      config_get_default('bgp', 'timer_bestpath_limit')
    end

    def default_timer_bestpath_limit_always
      return nil if platform == :ios_xr && @vrf != 'default'
      config_get_default('bgp', 'timer_bestpath_limit_always')
    end
  end
end
