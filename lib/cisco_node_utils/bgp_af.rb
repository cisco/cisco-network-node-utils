# -*- coding: utf-8 -*-
# August 2015, Richard Wellum
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
require_relative 'bgp'
require_relative 'logger'

module Cisco
  # RouterBgpAF - node utility class for BGP address-family config management
  class RouterBgpAF < NodeUtil
    def initialize(asn, vrf, af, instantiate=true)
      fail ArgumentError if vrf.to_s.empty? || af.to_s.empty?
      err_msg = '"af" argument must be an array of two string values ' \
        'containing an afi + safi tuple'
      fail ArgumentError, err_msg unless af.is_a?(Array) || af.length == 2
      @asn = RouterBgp.validate_asnum(asn)
      @vrf = vrf
      @afi, @safi = af
      set_args_keys_default
      create if instantiate
    end

    def self.afs
      af_hash = {}
      RouterBgp.routers.each do |asn, vrfs|
        af_hash[asn] = {}
        vrfs.keys.each do |vrf_name|
          get_args = { asnum: asn }
          get_args[:vrf] = vrf_name unless vrf_name == 'default'
          # Call yaml and search for address-family statements
          af_list = config_get('bgp_af', 'all_afs', get_args)

          next if af_list.nil?

          af_hash[asn][vrf_name] = {}
          af_list.each do |af|
            af_hash[asn][vrf_name][af] =
              RouterBgpAF.new(asn, vrf_name, af, false)
          end
        end
      end
      af_hash
    end

    def create
      if platform == :nexus
        Feature.bgp_enable
        Feature.nv_overlay_evpn_enable if @safi[/evpn/]
      end
      set_args_keys(state: '')
      config_set('bgp', 'address_family', @set_args)
    end

    def destroy
      set_args_keys(state: 'no')
      config_set('bgp', 'address_family', @set_args)
    end

    #
    # Helper methods to delete @set_args hash keys
    #
    def set_args_keys_default
      keys = { asnum: @asn, afi: @afi, safi: @safi }
      keys[:vrf] = @vrf unless @vrf == 'default'
      @get_args = @set_args = keys
    end

    def set_args_keys(hash={}) # rubocop:disable Style/AccessorMethodName
      set_args_keys_default
      @set_args = @get_args.merge!(hash) unless hash.empty?
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    def fail_unsupported(callee)
      fail Cisco::UnsupportedError.new('bgp_af', callee.to_s)
    end

    #
    # Client to client (Getter/Setter/Default)
    #

    def client_to_client=(state)
      # IOS XR uses "client-to-client reflection disable",
      #     so turning it "on" means disabling it.
      # Thus we invert the desired state before telling the CLI what to do:
      state = !state if ios_xr?
      set_args_keys(state: (state ? '' : 'no'))
      config_set('bgp_af', 'client_to_client', @set_args)
    end

    #
    # Default Information (Getter/Setter/Default)
    #

    def default_information_originate
      config_get('bgp_af', 'default_information_originate', @get_args)
    end

    #
    # Next Hop route map (Getter/Setter/Default)
    #
    def next_hop_route_map=(route_map)
      route_map.strip!
      if route_map.empty?
        state = 'no'
        # Dummy routemap required if not configured.
        if next_hop_route_map.empty?
          route_map = 'dummy_routemap'
        else
          route_map = next_hop_route_map
        end
      end
      set_args_keys(state: state, route_map: route_map)
      config_set('bgp_af', 'next_hop_route_map', @set_args)
    end

    #
    # additional paths (Getter/Setter/Default)
    #
    def additional_paths_selection=(route_map)
      route_map.strip!
      if route_map.empty?
        state = 'no'
        # Dummy routemap required if not configured.
        if additional_paths_selection.empty?
          route_map = 'dummy_routemap'
        else
          route_map = additional_paths_selection
        end
      end
      set_args_keys(state: state, route_map: route_map, route_policy: route_map)
      config_set('bgp_af', 'additional_paths_selection', @set_args)
    end

    # advertise_l2vpn_evpn
    def advertise_l2vpn_evpn
      config_get('bgp_af', 'advertise_l2vpn_evpn', @get_args)
    end

    def advertise_l2vpn_evpn=(state)
      Feature.nv_overlay_evpn_enable if platform == :nexus
      set_args_keys(state: (state ? '' : 'no'))
      config_set('bgp_af', 'advertise_l2vpn_evpn', @set_args)
    end

    #
    # dampen_igp_metric (Getter/Setter/Default)
    #

    # dampen_igp_metric
    def dampen_igp_metric
      match = config_get('bgp_af', 'dampen_igp_metric', @get_args)
      if match.is_a?(Array)
        return nil if match[0] == 'no '
        return match[1].to_i if match[1]
      end
      default_dampen_igp_metric
    end

    def dampen_igp_metric=(val)
      set_args_keys(state: (val.nil?) ? 'no' : '',
                    num:   (val.nil?) ? '' : val)
      config_set('bgp_af', 'dampen_igp_metric', @set_args)
    end

    #
    # dampening (Getter/Setter/Default)
    #

    # The data presented to or retrieved from the config_set and config_get
    # for dampening is one of 4 possibilities:
    #
    # Value                     Meaning
    # -----                     -------
    # nil                       Dampening is not configured
    # []                        Dampening is configured with no options
    # [1,3,4,5,nil]             Dampening + decay, reuse, suppress, suppress_max
    # [nil,nil,nil,nil,'route-map'] Dampening + routemap
    def dampening
      data = config_get('bgp_af', 'dampening', @get_args)
      return nil if data.nil? # no dampening

      data = data.flatten

      # dampening nil nil nil nil nil
      val = []

      if !data[4].nil?
        # dampening nil nil nil nil route-map
        val = data[4]
      elsif !data[3].nil? && data[4].nil?
        # dampening 1 2 3 4 nil
        val = data[0..3]
      end

      val
    end

    # Return true if dampening is enabled, else false.
    def dampening_state
      !dampening.nil?
    end

    # For all of the following dampening getters, half_time, reuse_time,
    # suppress_time, and max_suppress_time, return nil if dampening
    # is not configured, but also return nil if a dampening routemap
    # is configured because they are mutually exclusive.
    def dampening_half_time
      return nil if dampening.nil? || dampening_routemap_configured?
      if dampening.is_a?(Array) && !dampening.empty?
        dampening[0].to_i
      else
        default_dampening_half_time
      end
    end

    def dampening_reuse_time
      return nil if dampening.nil? || dampening_routemap_configured?
      if dampening.is_a?(Array) && !dampening.empty?
        dampening[1].to_i
      else
        default_dampening_reuse_time
      end
    end

    def dampening_suppress_time
      return nil if dampening.nil? || dampening_routemap_configured?
      if dampening.is_a?(Array) && !dampening.empty?
        dampening[2].to_i
      else
        default_dampening_suppress_time
      end
    end

    def dampening_max_suppress_time
      return nil if dampening.nil? || dampening_routemap_configured?
      if dampening.is_a?(Array) && !dampening.empty?
        dampening[3].to_i
      else
        default_dampening_max_suppress_time
      end
    end

    def dampening_routemap
      if dampening.nil? || (dampening.is_a?(String) && dampening.size > 0)
        return dampening
      end
      default_dampening_routemap
    end

    def dampening_routemap_configured?
      if dampening_routemap.is_a?(String) && dampening_routemap.size > 0
        true
      else
        false
      end
    end

    def dampening=(damp_array)
      fail ArgumentError if damp_array.kind_of?(Array) &&
                            !(damp_array.length == 4 ||
                              damp_array.length == 0)

      # Set defaults args
      state = ''
      route_map = ''
      decay = ''
      reuse = ''
      suppress = ''
      suppress_max = ''

      if damp_array.nil?
        # 'no dampening ...' command - no dampening handles all cases
        state = 'no'
        Cisco::Logger.debug("Dampening 'no dampening'")
      elsif damp_array.empty?
        # 'dampening' command - nothing to do here
        Cisco::Logger.debug("Dampening 'dampening'")
      elsif damp_array.size == 4
        # 'dampening dampening_decay dampening_reuse \
        #   dampening_suppress dampening_suppress_max' command
        decay =        damp_array[0]
        reuse =        damp_array[1]
        suppress =     damp_array[2]
        suppress_max = damp_array[3]
        Cisco::Logger.debug("Dampening 'dampening #{damp_array.join(' ')}''")
      else
        # 'dampening route-map WORD' command
        route_map = "route-map #{damp_array}"    if platform == :nexus
        route_map = "route-policy #{damp_array}" if platform == :ios_xr
        route_map.strip!
        Cisco::Logger.debug("Dampening 'dampening route-map #{route_map}'")
      end

      # Set final args
      set_args_keys(
        state:        state,
        route_map:    route_map,
        decay:        decay,
        reuse:        reuse,
        suppress:     suppress,
        suppress_max: suppress_max,
      )

      Cisco::Logger.debug("Dampening args=#{@set_args}")
      config_set('bgp_af', 'dampening', @set_args)
    end

    #
    # Distance (Getter/Setter/Default)
    #
    def distance_set(ebgp, ibgp, local)
      set_args_keys(state: '', ebgp: ebgp, ibgp: ibgp, local: local)
      config_set('bgp_af', 'distance', @set_args)
    end

    def distance_ebgp
      ebgp, _ibgp, _local = distance
      return default_distance_ebgp if ebgp.nil?
      ebgp.to_i
    end

    def distance_ibgp
      _ebgp, ibgp, _local = distance
      return default_distance_ibgp if ibgp.nil?
      ibgp.to_i
    end

    def distance_local
      _ebgp, _ibgp, local = distance
      return default_distance_local if local.nil?
      local.to_i
    end

    #
    # default_metric (Getter/Setter/Default)
    #

    def default_metric
      config_get('bgp_af', 'default_metric', @get_args)
    end

    def default_metric=(val)
      # To remove the default_metric you can not use 'no default_metric'
      # dummy metric to work around this
      dummy_metric = 1
      set_args_keys(state: (val == default_default_metric) ? 'no' : '',
                    num:   (val == default_default_metric) ? dummy_metric : val)
      config_set('bgp_af', 'default_metric', @set_args)
    end

    #
    # inject_map (Getter/Setter/Default)
    #

    def inject_map
      cmds = config_get('bgp_af', 'inject_map', @get_args)
      cmds.nil? ? nil : cmds.each(&:compact!).sort
    end

    def inject_map=(should_list)
      c = inject_map
      fail_unsupported(__callee__) if c.nil?
      delta_hash = Utils.delta_add_remove(should_list, c)
      return if delta_hash.values.flatten.empty?
      [:add, :remove].each do |action|
        Cisco::Logger.debug("inject_map delta #{@get_args}\n #{action}: " \
                            "#{delta_hash[action]}")
        delta_hash[action].each do |inject, exist, copy|
          # inject & exist are mandatory, copy is optional
          state = (action == :add) ? '' : 'no'
          copy = 'copy-attributes' unless copy.nil?
          set_args_keys(state: state, inject: inject, exist: exist, copy: copy)
          config_set('bgp_af', 'inject_map', @set_args)
        end
      end
    end

    #
    # maximum_paths (Getter/Setter/Default)
    #

    def maximum_paths=(val)
      set_args_keys(state: (val == default_maximum_paths) ? 'no' : '',
                    num:   (val == default_maximum_paths) ? '' : val)
      config_set('bgp_af', 'maximum_paths', @set_args)
    end

    def maximum_paths_ibgp=(val)
      set_args_keys(state: (val == default_maximum_paths_ibgp) ? 'no' : '',
                    num:   (val == default_maximum_paths_ibgp) ? '' : val)
      config_set('bgp_af', 'maximum_paths_ibgp', @set_args)
    end

    #
    # Networks (Getter/Setter/Default)
    #

    # Build an array of all network commands currently on the device
    def networks
      c = config_get('bgp_af', 'networks', @get_args)
      c.nil? ? nil : c.each(&:compact!)
    end

    # networks setter.
    # Processes a hash of network commands from delta_add_remove().
    def networks=(should_list)
      delta_hash = Utils.delta_add_remove(should_list, networks)
      return if delta_hash.values.flatten.empty?
      [:add, :remove].each do |action|
        Cisco::Logger.debug("networks delta #{@get_args}\n #{action}: " \
                            "#{delta_hash[action]}")
        delta_hash[action].each do |network, route_map_policy|
          state = (action == :add) ? '' : 'no'
          network = Utils.process_network_mask(network)
          unless route_map_policy.nil?
            route_map = "route-map #{route_map_policy}"
            route_policy = "route-policy #{route_map_policy}"
          end
          set_args_keys(state: state, network: network, route_map: route_map,
                        route_policy: route_policy)
          config_set('bgp_af', 'networks', @set_args)
        end
      end
    end

    #
    # Redistribute (Getter/Setter/Default)
    #

    # Build an array of all redistribute commands currently on the device
    def redistribute
      c = config_get('bgp_af', 'redistribute', @get_args)
      c.nil? ? nil : c.each(&:compact!).sort
    end

    # redistribute setter.
    # Process a hash of redistribute commands from delta_add_remove().
    def redistribute=(should)
      delta_hash = Utils.delta_add_remove(should, redistribute)
      return if delta_hash.values.flatten.empty?
      [:add, :remove].each do |action|
        Cisco::Logger.debug("redistribute delta #{@get_args}\n #{action}: " \
                            "#{delta_hash[action]}")
        delta_hash[action].each do |protocol, policy|
          state = (action == :add) ? '' : 'no'
          set_args_keys(state: state, protocol: protocol, policy: policy)

          # route-map/policy may be optional on some platforms
          cmd = policy.nil? ? 'redistribute' : 'redistribute_policy'
          config_set('bgp_af', cmd, @set_args)
        end
      end
    end

    def default_redistribute
      config_get_default('bgp_af', 'redistribute')
    end

    #
    # Table Map (Getter/Setter/Default)
    #

    def table_map_set(map, filter=false)
      # To remove table map we can not use 'no table-map'
      # Dummy-map specified to work around this
      if filter
        attr = 'table_map_filter'
      else
        attr = 'table_map'
      end
      dummy_map = 'dummy'
      if map == default_table_map
        @set_args[:state] = 'no'
        @set_args[:map] = dummy_map
      else
        @set_args[:state] = ''
        @set_args[:map] = map
      end
      config_set('bgp_af', attr, @set_args)
      set_args_keys_default
    end

    ##########################################
    # Universal Getter, Default Getter, and Setter
    #
    def method_missing(*args)
      name = args[0].to_s
      if args.length == 1 # Getter
        if name =~ /^default_(.*)$/
          config_get_default('bgp_af', Regexp.last_match(1))
        else
          config_get('bgp_af', name, @get_args)
        end
      elsif args.length == 2 && name =~ /^(.*)=$/ # Setter
        set_args_keys(state: args[1] ? '' : 'no')
        config_set('bgp_af', Regexp.last_match(1), @set_args)
      else
        super
      end
    end

    # Is the given name available in the YAML?
    def respond_to?(method_sym, _include_private=false)
      name = method_sym.to_s
      key = :getter?
      if name =~ /^(.*)=$/
        name = Regexp.last_match(1)
        # Use table_map_set() to set these properties
        return false if name == 'table_map' || name == 'table_map_filter'
        key = :setter?
      elsif name =~ /^default_(.*)$/
        name = Regexp.last_match(1)
        key = :default_value?
      end
      begin
        ref = node.cmd_ref.lookup('bgp_af', name)
        ref.send(key)
      rescue IndexError
        super
      end
    end
  end
end
