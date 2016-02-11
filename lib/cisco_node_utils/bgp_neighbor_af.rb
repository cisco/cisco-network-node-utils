#
# NXAPI implementation of RouterBgpNeighborAF class
#
# August 2015 Chris Van Heuveln
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

module Cisco
  # RouterBgpNeighborAF - node utility class for BGP per-neighbor, per-AF config
  class RouterBgpNeighborAF < NodeUtil
    def initialize(asn, vrf, nbr, af, instantiate=true)
      validate_args(asn, vrf, nbr, af)
      create if instantiate
    end

    def self.afs
      af_hash = {}
      RouterBgp.routers.each do |asn, vrfs|
        af_hash[asn] = {}

        vrfs.keys.each do |vrf|
          af_hash[asn][vrf] = {}
          get_args = { asnum: asn }
          get_args[:vrf] = vrf unless vrf == 'default'

          nbrs = config_get('bgp_neighbor', 'all_neighbors', get_args)
          next if nbrs.nil?
          nbrs.each do |nbr|
            af_hash[asn][vrf][nbr] = {}
            get_args[:nbr] = nbr
            afs = config_get('bgp_neighbor_af', 'all_afs', get_args)

            next if afs.nil?
            afs.each do |af|
              af_hash[asn][vrf][nbr][af] =
                RouterBgpNeighborAF.new(asn, vrf, nbr, af, false)
            end
          end
        end
      end
      af_hash
    rescue Cisco::CliError => e
      # cmd will syntax reject when feature is not enabled
      raise unless e.clierror =~ /Syntax error/
      return {}
    end

    def validate_args(asn, vrf, nbr, af)
      fail ArgumentError unless
        vrf.is_a?(String) && (vrf.length > 0)
      fail ArgumentError unless
        nbr.is_a?(String) && (nbr.length > 0)
      fail ArgumentError, "'af' must be an array specifying afi and safi" unless
        af.is_a?(Array) || af.length == 2

      nbr = Utils.process_network_mask(nbr)
      @asn = RouterBgp.validate_asnum(asn)
      @vrf = vrf
      @nbr = nbr
      @afi, @safi = af
      set_args_keys_default
    end

    def set_args_keys_default
      keys = { asnum: @asn, nbr: @nbr, afi: @afi, safi: @safi }
      keys[:vrf] = @vrf unless @vrf == 'default'
      @get_args = @set_args = keys
    end

    # rubocop:disable Style/AccessorMethodName
    def set_args_keys(hash={})
      set_args_keys_default
      @set_args = @get_args.merge!(hash) unless hash.empty?
    end
    # rubocop:enable Style/AccessorMethodNamefor

    def create
      Feature.bgp_enable
      set_args_keys(state: '')
      config_set('bgp_neighbor', 'af', @set_args)
    end

    def destroy
      set_args_keys(state: 'no')
      config_set('bgp_neighbor', 'af', @set_args)
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    # -----------------------
    # <state> advertise-map <map1> exist-map <map2>

    # Returns ['<map1>', '<map2>']
    def advertise_map_exist
      config_get('bgp_neighbor_af', 'advertise_map_exist', @get_args)
    end

    def advertise_map_exist=(arr)
      if arr.empty?
        state = 'no'
        map1, map2 = advertise_map_exist
      else
        map1, map2 = arr
      end
      set_args_keys(state: state, map1: map1, map2: map2)
      config_set('bgp_neighbor_af', 'advertise_map_exist', @set_args)
    end

    def default_advertise_map_exist
      config_get_default('bgp_neighbor_af', 'advertise_map_exist')
    end

    # -----------------------
    # <state> advertise-map <map1> non-exist-map <map2> }

    # Returns ['<map1>', '<map2>']
    def advertise_map_non_exist
      config_get('bgp_neighbor_af', 'advertise_map_non_exist', @get_args)
    end

    def advertise_map_non_exist=(arr)
      if arr.empty?
        state = 'no'
        map1, map2 = advertise_map_non_exist
      else
        map1, map2 = arr
      end
      set_args_keys(state: state, map1: map1, map2: map2)
      config_set('bgp_neighbor_af', 'advertise_map_non_exist', @set_args)
    end

    def default_advertise_map_non_exist
      config_get_default('bgp_neighbor_af', 'advertise_map_non_exist')
    end

    # -----------------------
    # <state> allowas-in <max>
    # Nvgens as True -OR- max-occurrences integer
    def allowas_in_get
      val = config_get('bgp_neighbor_af', 'allowas_in', @get_args)
      return nil if val.nil?
      val.split.last.to_i
    end

    def allowas_in
      allowas_in_get.nil? ? false : true
    end

    def allowas_in_max
      val = allowas_in_get
      # val.zero? check below is needed to handle a cli defect wherein the
      # default max value does not reliably nvgen
      val = default_allowas_in_max if val.nil? || val.zero?
      val
    end

    def allowas_in_set(state, max=nil)
      set_args_keys(state: (state ? '' : 'no'), max: max)
      config_set('bgp_neighbor_af', 'allowas_in', @set_args)
    end

    def default_allowas_in
      config_get_default('bgp_neighbor_af', 'allowas_in')
    end

    def default_allowas_in_max
      config_get_default('bgp_neighbor_af', 'allowas_in_max')
    end

    # -----------------------
    # <state> as-override
    def as_override
      state = config_get('bgp_neighbor_af', 'as_override', @get_args)
      state ? true : false
    end

    def as_override=(state)
      set_args_keys(state: (state ? '' : 'no'))
      config_set('bgp_neighbor_af', 'as_override', @set_args)
    end

    def default_as_override
      config_get_default('bgp_neighbor_af', 'as_override')
    end

    # -----------------------
    # <state> capability additional-paths receive <disable>
    #   :enable  = capability additional-paths receive
    #   :disable = capability additional-paths receive disable
    #   :inherit = no capability additional-paths receive
    def additional_paths_receive
      val = config_get('bgp_neighbor_af', 'additional_paths_receive', @get_args)
      return default_additional_paths_receive if val.nil?
      /disable/.match(val) ? :disable : :enable
    end

    def additional_paths_receive=(val)
      val = val.to_sym
      if val == default_additional_paths_receive
        set_args_keys(state: 'no', disable: '')
      else
        set_args_keys(state: '', disable: (val == :enable) ? '' : 'disable')
      end
      config_set('bgp_neighbor_af', 'additional_paths_receive', @set_args)
    end

    def default_additional_paths_receive
      config_get_default('bgp_neighbor_af', 'additional_paths_receive').to_sym
    end

    # -----------------------
    # <state> capability additional-paths send <disable>
    #   :enable  = capability additional-paths send
    #   :disable = capability additional-paths send disable
    #   :inherit = no capability additional-paths send
    def additional_paths_send
      val = config_get('bgp_neighbor_af', 'additional_paths_send', @get_args)
      return default_additional_paths_send if val.nil?
      /disable/.match(val) ? :disable : :enable
    end

    def additional_paths_send=(val)
      val = val.to_sym
      if val == default_additional_paths_send
        set_args_keys(state: 'no', disable: '')
      else
        set_args_keys(state: '', disable: (val == :enable) ? '' : 'disable')
      end
      config_set('bgp_neighbor_af', 'additional_paths_send', @set_args)
    end

    def default_additional_paths_send
      config_get_default('bgp_neighbor_af', 'additional_paths_send').to_sym
    end

    # -----------------------
    # <state> default-originate [ route-map <map> ]
    # Nvgens as True with optional 'route-map <map>'
    def default_originate_get
      val = config_get('bgp_neighbor_af', 'default_originate', @get_args)
      return nil unless val
      (val[/route-map/]) ? val.split.last : true
    end

    def default_originate
      default_originate_get.nil? ? false : true
    end

    def default_originate_route_map
      val = default_originate_get
      return default_default_originate_route_map if val.nil?
      val.is_a?(String) ? val : nil
    end

    def default_originate_set(state, map=nil)
      map = "route-map #{map}" unless map.nil?
      set_args_keys(state: (state ? '' : 'no'), map: map)
      config_set('bgp_neighbor_af', 'default_originate', @set_args)
    end

    def default_default_originate
      config_get_default('bgp_neighbor_af', 'default_originate')
    end

    def default_default_originate_route_map
      config_get_default('bgp_neighbor_af', 'default_originate_route_map')
    end

    # -----------------------
    # <state> disable-peer-as-check
    def disable_peer_as_check
      state = config_get('bgp_neighbor_af', 'disable_peer_as_check', @get_args)
      state ? true : default_disable_peer_as_check
    end

    def disable_peer_as_check=(state)
      set_args_keys(state: (state ? '' : 'no'))
      config_set('bgp_neighbor_af', 'disable_peer_as_check', @set_args)
    end

    def default_disable_peer_as_check
      config_get_default('bgp_neighbor_af', 'disable_peer_as_check')
    end

    # -----------------------
    # <state> filter-list <str> in
    def filter_list_in
      config_get('bgp_neighbor_af', 'filter_list_in', @get_args)
    end

    def filter_list_in=(str)
      str.strip! unless str.nil?
      if str == default_filter_list_in
        state = 'no'
        # Current filter-list name is required for removal
        str = filter_list_in
        return if str.nil?
      end
      set_args_keys(state: state, str: str)
      config_set('bgp_neighbor_af', 'filter_list_in', @set_args)
    end

    def default_filter_list_in
      config_get_default('bgp_neighbor_af', 'filter_list_in')
    end

    # -----------------------
    # <state> filter-list <str> out
    def filter_list_out
      config_get('bgp_neighbor_af', 'filter_list_out', @get_args)
    end

    def filter_list_out=(str)
      str.strip! unless str.nil?
      if str == default_filter_list_out
        state = 'no'
        # Current filter-list name is required for removal
        str = filter_list_out
      end
      set_args_keys(state: state, str: str)
      config_set('bgp_neighbor_af', 'filter_list_out', @set_args)
    end

    def default_filter_list_out
      config_get_default('bgp_neighbor_af', 'filter_list_out')
    end

    # -----------------------
    # <state> maximum-prefix <limit> <threshold> <opt>
    #
    # <threshold> : optional
    # <opt> : optional = [ restart <interval> | warning-only ]
    #
    def max_prefix_get
      str = config_get('bgp_neighbor_af', 'max_prefix', @get_args)
      return nil if str.nil?

      regexp = Regexp.new('maximum-prefix (?<limit>\d+)' \
                          ' *(?<threshold>\d+)?' \
                          ' *(?<opt>restart|warning-only)?' \
                          ' *(?<interval>\d+)?')
      regexp.match(str)
    end

    def max_prefix_set(limit, threshold=nil, opt=nil)
      state = limit.nil? ? 'no' : ''
      unless opt.nil?
        opt = opt.respond_to?(:to_i) ? "restart #{opt}" : 'warning-only'
      end
      set_args_keys(state: state, limit: limit,
                    threshold: threshold, opt: opt)
      config_set('bgp_neighbor_af', 'max_prefix', @set_args)
    end

    def max_prefix_limit
      val = max_prefix_get
      return default_max_prefix_limit if val.nil?
      val[:limit].to_i
    end

    def max_prefix_interval
      val = max_prefix_get
      return default_max_prefix_interval if val.nil?
      (val[:interval].nil?) ? nil : val[:interval].to_i
    end

    def max_prefix_threshold
      val = max_prefix_get
      return default_max_prefix_threshold if val.nil?
      (val[:threshold].nil?) ? nil : val[:threshold].to_i
    end

    def max_prefix_warning
      val = max_prefix_get
      return default_max_prefix_warning if val.nil?
      (val[:opt] == 'warning-only') ? true : nil
    end

    def default_max_prefix_limit
      config_get_default('bgp_neighbor_af', 'max_prefix_limit')
    end

    def default_max_prefix_interval
      config_get_default('bgp_neighbor_af', 'max_prefix_interval')
    end

    def default_max_prefix_threshold
      config_get_default('bgp_neighbor_af', 'max_prefix_threshold')
    end

    def default_max_prefix_warning
      config_get_default('bgp_neighbor_af', 'max_prefix_warning')
    end

    # -----------------------
    # <state> next-hop-self
    def next_hop_self
      state = config_get('bgp_neighbor_af', 'next_hop_self', @get_args)
      state ? true : false
    end

    def next_hop_self=(state)
      set_args_keys(state: (state ? '' : 'no'))
      config_set('bgp_neighbor_af', 'next_hop_self', @set_args)
    end

    def default_next_hop_self
      config_get_default('bgp_neighbor_af', 'next_hop_self')
    end

    # -----------------------
    # <state> next-hop-third-party
    def next_hop_third_party
      state = config_get('bgp_neighbor_af', 'next_hop_third_party', @get_args)
      state ? true : false
    end

    def next_hop_third_party=(state)
      set_args_keys(state: (state ? '' : 'no'))
      config_set('bgp_neighbor_af', 'next_hop_third_party', @set_args)
    end

    def default_next_hop_third_party
      config_get_default('bgp_neighbor_af', 'next_hop_third_party')
    end

    # -----------------------
    # <state> prefix-list <str> in
    def prefix_list_in
      config_get('bgp_neighbor_af', 'prefix_list_in', @get_args)
    end

    def prefix_list_in=(str)
      str.strip! unless str.nil?
      if str == default_prefix_list_in
        state = 'no'
        # Current prefix-list name is required for removal
        str = prefix_list_in
        return if str.nil?
      end
      set_args_keys(state: state, str: str)
      config_set('bgp_neighbor_af', 'prefix_list_in', @set_args)
    end

    def default_prefix_list_in
      config_get_default('bgp_neighbor_af', 'prefix_list_in')
    end

    # -----------------------
    # <state> prefix-list <str> out
    def prefix_list_out
      config_get('bgp_neighbor_af', 'prefix_list_out', @get_args)
    end

    def prefix_list_out=(str)
      str.strip! unless str.nil?
      if str == default_prefix_list_out
        state = 'no'
        # Current prefix-list name is required for removal
        str = prefix_list_out
      end
      set_args_keys(state: state, str: str)
      config_set('bgp_neighbor_af', 'prefix_list_out', @set_args)
    end

    def default_prefix_list_out
      config_get_default('bgp_neighbor_af', 'prefix_list_out')
    end

    # -----------------------
    # <state> route-map <str> in
    def route_map_in
      config_get('bgp_neighbor_af', 'route_map_in', @get_args)
    end

    def route_map_in=(str)
      str.strip! unless str.nil?
      if str == default_route_map_in
        state = 'no'
        # Current route-map name is required for removal
        str = route_map_in
        return if str.nil?
      end
      set_args_keys(state: state, str: str)
      config_set('bgp_neighbor_af', 'route_map_in', @set_args)
    end

    def default_route_map_in
      config_get_default('bgp_neighbor_af', 'route_map_in')
    end

    # -----------------------
    # <state> route-map <str> out
    def route_map_out
      config_get('bgp_neighbor_af', 'route_map_out', @get_args)
    end

    def route_map_out=(str)
      str.strip! unless str.nil?
      if str == default_route_map_out
        state = 'no'
        # Current route-map name is required for removal
        str = route_map_out
      end
      set_args_keys(state: state, str: str)
      config_set('bgp_neighbor_af', 'route_map_out', @set_args)
    end

    def default_route_map_out
      config_get_default('bgp_neighbor_af', 'route_map_out')
    end

    # -----------------------
    # <state route-reflector-client
    def route_reflector_client
      config_get('bgp_neighbor_af', 'route_reflector_client', @get_args)
    end

    def route_reflector_client=(state)
      set_args_keys(state: (state ? '' : 'no'))
      config_set('bgp_neighbor_af', 'route_reflector_client', @set_args)
    end

    def default_route_reflector_client
      config_get_default('bgp_neighbor_af', 'route_reflector_client')
    end

    # -----------------------
    # <state> send-community [ both | extended | standard ]
    # NOTE: 'standard' is default but does not nvgen on some platforms
    # Returns: none, both, extended, or standard
    def send_community
      val = config_get('bgp_neighbor_af', 'send_community', @get_args)
      return default_send_community if val.nil?
      val = val.split.last
      return 'standard' if val[/send-community/] # Workaround
      val
    end

    def send_community=(val)
      if val[/none/]
        state = 'no'
        val = 'both'
      end
      if val[/extended|standard/]
        case send_community
        when /both/
          state = 'no'
          # Unset the opposite property
          val = val[/extended/] ? 'standard' : 'extended'

        when /extended|standard/
          # This is an additive property therefore remove the entire command
          # when switching from: ext <--> std
          set_args_keys(state: 'no', attr: 'both')
          config_set('bgp_neighbor_af', 'send_community', @set_args)
          state = ''
        end
      end
      set_args_keys(state: state, attr: val)
      config_set('bgp_neighbor_af', 'send_community', @set_args)
    end

    def default_send_community
      config_get_default('bgp_neighbor_af', 'send_community')
    end

    # -----------------------
    # <state> soft-reconfiguration inbound <always>
    #   :enable  = soft-reconfiguration inbound
    #   :always = soft-reconfiguration inbound always
    #   :inherit = no soft-reconfiguration inbound
    def soft_reconfiguration_in
      val = config_get('bgp_neighbor_af', 'soft_reconfiguration_in', @get_args)
      return default_soft_reconfiguration_in if val.nil?
      /always/.match(val) ? :always : :enable
    end

    def soft_reconfiguration_in=(val)
      val = val.to_sym
      if val == default_soft_reconfiguration_in
        set_args_keys(state: 'no', always: '')
      else
        set_args_keys(state: '', always: (val == :enable) ? '' : 'always')
      end
      config_set('bgp_neighbor_af', 'soft_reconfiguration_in', @set_args)
    end

    def default_soft_reconfiguration_in
      config_get_default('bgp_neighbor_af', 'soft_reconfiguration_in').to_sym
    end

    # -----------------------
    # <state> soo <str>
    def soo
      config_get('bgp_neighbor_af', 'soo', @get_args)
    end

    def soo=(str)
      str.strip! unless str.nil?
      if str == default_soo
        state = 'no'
        str = soo
      end
      set_args_keys(state: state, str: str)
      config_set('bgp_neighbor_af', 'soo', @set_args)
    end

    def default_soo
      config_get_default('bgp_neighbor_af', 'soo')
    end

    # -----------------------
    # <state> suppress-inactive
    def suppress_inactive
      config_get('bgp_neighbor_af', 'suppress_inactive', @get_args)
    end

    def suppress_inactive=(state)
      set_args_keys(state: (state ? '' : 'no'))
      config_set('bgp_neighbor_af', 'suppress_inactive', @set_args)
    end

    def default_suppress_inactive
      config_get_default('bgp_neighbor_af', 'suppress_inactive')
    end

    # -----------------------
    # <state> unsuppress-map <str>
    def unsuppress_map
      config_get('bgp_neighbor_af', 'unsuppress_map', @get_args)
    end

    def unsuppress_map=(str)
      str.strip! unless str.nil?
      if str == default_unsuppress_map
        state = 'no'
        str = unsuppress_map
      end
      set_args_keys(state: state, str: str)
      config_set('bgp_neighbor_af', 'unsuppress_map', @set_args)
    end

    def default_unsuppress_map
      config_get_default('bgp_neighbor_af', 'unsuppress_map')
    end

    # -----------------------
    # <state> weight <int>
    def weight
      config_get('bgp_neighbor_af', 'weight', @get_args)
    end

    def weight=(int)
      if int == default_weight
        state = 'no'
        int = ''
      end
      set_args_keys(state: state, int: int)
      config_set('bgp_neighbor_af', 'weight', @set_args)
    end

    def default_weight
      config_get_default('bgp_neighbor_af', 'weight')
    end
  end
end
