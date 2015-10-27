# -*- coding: utf-8 -*-
# August 2015, Richard Wellum
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

require File.join(File.dirname(__FILE__), 'cisco_cmn_utils')
require File.join(File.dirname(__FILE__), 'node_util')
require File.join(File.dirname(__FILE__), 'bgp')

module Cisco
  # RouterBgpAF - node utility class for BGP address-family config management
  class RouterBgpAF < NodeUtil
    def initialize(asn, vrf, af, instantiate=true)
      fail ArgumentError if vrf.to_s.empty? || af.to_s.empty?
      err_msg = '"af" argument must be an array of two string values ' \
        'containing an afi + safi tuple'
      fail ArgumentError, err_msg unless af.is_a?(Array) || af.length == 2
      @asn = RouterBgp.process_asnum(asn)
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
          get_args[:vrf] = vrf_name unless (vrf_name == 'default')
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

    #
    # Client to client (Getter/Setter/Default)
    #
    def client_to_client
      state = config_get('bgp_af', 'client_to_client', @get_args)
      state ? true : false
    end

    def client_to_client=(state)
      state = (state ? '' : 'no')
      set_args_keys(state: state)
      config_set('bgp_af', 'client_to_client', @set_args)
    end

    def default_client_to_client
      config_get_default('bgp_af', 'client_to_client')
    end

    #
    # Default Information (Getter/Setter/Default)
    #
    def default_information_originate
      state = config_get('bgp_af', 'default_information', @get_args)
      state ? true : false
    end

    def default_information_originate=(state)
      state = (state ? '' : 'no')
      set_args_keys(state: state)
      config_set('bgp_af', 'default_information', @set_args)
    end

    def default_default_information_originate
      config_get_default('bgp_af', 'default_information')
    end

    #
    # Next Hop route map (Getter/Setter/Default)
    #
    def next_hop_route_map
      route_map = config_get('bgp_af', 'next_hop_route_map', @get_args)
      return '' if route_map.nil?
      route_map.shift.strip
    end

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

    def default_next_hop_route_map
      config_get_default('bgp_af', 'next_hop_route_map')
    end

    #
    # additional paths (Getter/Setter/Default)
    #

    # additional_paths_send
    def additional_paths_send
      state = config_get('bgp_af', 'additional_paths_send', @get_args)
      state ? true : false
    end

    def additional_paths_send=(state)
      state = (state ? '' : 'no')
      set_args_keys(state: state)
      config_set('bgp_af', 'additional_paths_send', @set_args)
    end

    def default_additional_paths_send
      config_get_default('bgp_af', 'additional_paths_send')
    end

    # additional_paths_receive
    def additional_paths_receive
      state = config_get('bgp_af', 'additional_paths_receive', @get_args)
      state ? true : false
    end

    def additional_paths_receive=(state)
      state = (state ? '' : 'no')
      set_args_keys(state: state)
      config_set('bgp_af', 'additional_paths_receive', @set_args)
    end

    def default_additional_paths_receive
      config_get_default('bgp_af', 'additional_paths_receive')
    end

    # additional_paths_install
    def additional_paths_install
      state = config_get('bgp_af', 'additional_paths_install', @get_args)
      state ? true : false
    end

    def additional_paths_install=(state)
      state = (state ? '' : 'no')
      set_args_keys(state: state)
      config_set('bgp_af', 'additional_paths_install', @set_args)
    end

    def default_additional_paths_install
      config_get_default('bgp_af', 'additional_paths_install')
    end

    # additional_paths_selection
    def additional_paths_selection
      route_map = config_get('bgp_af', 'additional_paths_selection', @get_args)
      return '' if route_map.nil?
      route_map.shift.strip
    end

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
      set_args_keys(state: state, route_map: route_map)
      config_set('bgp_af', 'additional_paths_selection', @set_args)
    end

    def default_additional_paths_selection
      config_get_default('bgp_af', 'additional_paths_selection')
    end

    #
    # dampen_igp_metric (Getter/Setter/Default)
    #

    # dampen_igp_metric
    def dampen_igp_metric
      result = config_get('bgp_af', 'dampen_igp_metric', @get_args)
      result ? result.first.to_i : nil
    end

    def dampen_igp_metric=(val)
      set_args_keys(state: (val.nil?) ? 'no' : '',
                    num:   (val.nil?) ? '' : val)
      config_set('bgp_af', 'dampen_igp_metric', @set_args)
    end

    def default_dampen_igp_metric
      config_get_default('bgp_af', 'dampen_igp_metric')
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
    # '' || []                  Dampening is configured with no options
    # [1,3,4,5,nil]             Dampening + decay, reuse, suppress, suppress_max
    # [nil,nil,nil,'route-map'] Dampening + routemap
    def dampening
      data = config_get('bgp_af', 'dampening', @get_args)

      if data.nil?
        # no dampening
        return nil
      end

      data = data.flatten

      # dampening nil nil nil nil nil
      val = ''

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
      if dampening.is_a?(Array)
        dampening[0].to_i
      else
        default_dampening_half_time
      end
    end

    def dampening_reuse_time
      return nil if dampening.nil? || dampening_routemap_configured?
      if dampening.is_a?(Array)
        dampening[1].to_i
      else
        default_dampening_reuse_time
      end
    end

    def dampening_suppress_time
      return nil if dampening.nil? || dampening_routemap_configured?
      if dampening.is_a?(Array)
        dampening[2].to_i
      else
        default_dampening_suppress_time
      end
    end

    def dampening_max_suppress_time
      return nil if dampening.nil? || dampening_routemap_configured?
      if dampening.is_a?(Array)
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
        CiscoLogger.debug("Dampening 'no dampening'")
      elsif damp_array.empty?
        # 'dampening' command - nothing to do here
        CiscoLogger.debug("Dampening 'dampening'")
      elsif damp_array.size == 4
        # 'dampening dampening_decay dampening_reuse \
        #   dampening_suppress dampening_suppress_max' command
        decay =        damp_array[0]
        reuse =        damp_array[1]
        suppress =     damp_array[2]
        suppress_max = damp_array[3]
        CiscoLogger.debug("Dampening 'dampening #{damp_array.join(' ')}''")
      elsif route_map.is_a? String
        # 'dampening route-map WORD' command
        route_map = "route-map #{damp_array}"
        route_map.strip!
        CiscoLogger.debug("Dampening 'dampening #{route_map}'")
      else
        # Array not in a valid format
        fail ArgumentError
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
      CiscoLogger.debug("Dampening args=#{@set_args}")
      config_set('bgp_af', 'dampening', @set_args)
    end

    def default_dampening
      config_get_default('bgp_af', 'dampening')
    end

    def default_dampening_state
      config_get_default('bgp_af', 'dampening_state')
    end

    def default_dampening_max_suppress_time
      config_get_default('bgp_af', 'dampening_max_suppress_time')
    end

    def default_dampening_half_time
      config_get_default('bgp_af', 'dampening_half_time')
    end

    def default_dampening_reuse_time
      config_get_default('bgp_af', 'dampening_reuse_time')
    end

    def default_dampening_routemap
      config_get_default('bgp_af', 'dampening_routemap')
    end

    def default_dampening_suppress_time
      config_get_default('bgp_af', 'dampening_suppress_time')
    end

    #
    # maximum_paths (Getter/Setter/Default)
    #

    # maximum_paths
    def maximum_paths
      result = config_get('bgp_af', 'maximum_paths', @get_args)
      result.nil? ? default_maximum_paths : result.first.to_i
    end

    def maximum_paths=(val)
      set_args_keys(state: (val == default_maximum_paths) ? 'no' : '',
                    num:   (val == default_maximum_paths) ? '' : val)
      config_set('bgp_af', 'maximum_paths', @set_args)
    end

    def default_maximum_paths
      config_get_default('bgp_af', 'maximum_paths')
    end

    #
    # maximum_paths_ibgp (Getter/Setter/Default)
    #

    # maximum_paths_ibgp
    def maximum_paths_ibgp
      result = config_get('bgp_af', 'maximum_paths_ibgp', @get_args)
      result.nil? ? default_maximum_paths_ibgp : result.first.to_i
    end

    def maximum_paths_ibgp=(val)
      set_args_keys(state: (val == default_maximum_paths_ibgp) ? 'no' : '',
                    num:   (val == default_maximum_paths_ibgp) ? '' : val)
      config_set('bgp_af', 'maximum_paths_ibgp', @set_args)
    end

    def default_maximum_paths_ibgp
      config_get_default('bgp_af', 'maximum_paths_ibgp')
    end

    #
    # Networks (Getter/Setter/Default)
    #

    # Build an array of all network commands currently on the device
    def networks
      cmds = config_get('bgp_af', 'network', @get_args)
      cmds.nil? ? default_networks : cmds.each(&:compact!)
    end

    # networks setter.
    # Processes a hash of network commands from delta_add_remove().
    def networks=(should_list)
      delta_hash = delta_add_remove(should_list, networks)
      return if delta_hash.values.flatten.empty?
      [:add, :remove].each do |action|
        CiscoLogger.debug("networks delta #{@get_args}\n #{action}: " \
                          "#{delta_hash[action]}")
        delta_hash[action].each do |network, route_map|
          state = (action == :add) ? '' : 'no'
          network = Utils.process_network_mask(network)
          route_map = "route-map #{route_map}" unless route_map.nil?
          set_args_keys(state: state, network: network, route_map: route_map)
          config_set('bgp_af', 'network', @set_args)
        end
      end
    end

    # Helper to build a hash of add/remove commands.
    #   should: an array of expected cmds (manifest/recipe)
    #  current: an array of existing cmds on the device
    def delta_add_remove(should, current=[])
      # Remove nil entries from array
      should.each(&:compact!) unless should.empty?
      delta = { add: should - current, remove: current - should }

      # Delete entries from :remove if f1 is an update to an existing command
      delta[:add].each do |id, _|
        delta[:remove].delete_if { |f1, f2| [f1, f2] if f1.to_s == id.to_s }
      end
      delta
    end

    def default_networks
      config_get_default('bgp_af', 'network')
    end
  end
end
