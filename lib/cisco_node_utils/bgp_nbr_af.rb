#
# NXAPI implementation of RouterBgpNbrAF class
#
# August 2015 Chris Van Heuveln
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

require File.join(File.dirname(__FILE__), 'node')
require File.join(File.dirname(__FILE__), 'bgp')

module Cisco
class RouterBgpNbrAF
  @@node = Cisco::Node.instance

  def initialize(asn, vrf, nbr, af, instantiate=true)
    validate_args(asn, vrf, nbr, af)
    create if instantiate
  end

  def RouterBgpNbrAF.afs
    af_hash = {}
    RouterBgp.routers.each { |asn, vrfs|
      af_hash[asn] = {}

      vrfs.keys.each { |vrf|
        af_hash[asn][vrf] = {}
        get_args = { :asnum => asn }
        get_args[:vrf] = vrf unless (vrf == 'default')

        nbrs = @@node.config_get('bgp_neighbor', 'all_neighbors', get_args)
        next if nbrs.nil?
        nbrs.each { |nbr|
          af_hash[asn][vrf][nbr] = {}
          get_args[:nbr] = nbr
          afs = @@node.config_get('bgp_nbr_af', 'all_afs', get_args)

          next if afs.nil?
          afs.each { |af|
            af_hash[asn][vrf][nbr][af] =
              RouterBgpNbrAF.new(asn, vrf, nbr, af, false)
          }
        }
      }
    }
    af_hash
  rescue Cisco::CliError => e
    # cmd will syntax reject when feature is not enabled
    raise unless e.clierror =~ /Syntax error/
    return {}
  end

  def RouterBgpNbrAF.nbr_munge(nbr)
    # TBD: MOVE THIS INTO RouterBgpNeighbor
    # 'nbr' supports multiple formats which can nvgen differently:
    #   1.1.1.1      nvgens 1.1.1.1
    #   1.1.1.1/16   nvgens 1.1.0.0/16
    #   200:2::20/64 nvgens 200:2::/64
    addr, mask = nbr.split('/')
    addr = IPAddr.new(nbr).to_s
    addr = addr + '/' + mask unless mask.nil?
    addr
  end

  def validate_args(asn, vrf, nbr, af)
    asn = RouterBgp.process_asnum(asn)
    raise ArgumentError unless
      vrf.is_a?(String) and (vrf.length > 0)
    raise ArgumentError unless
      nbr.is_a?(String) and (nbr.length > 0)
    raise ArgumentError, "'af' must be an array specifying afi and safi" unless
      af.is_a? Array or af.length == 2

    nbr = RouterBgpNbrAF.nbr_munge(nbr)
    @asn, @vrf, @nbr = asn, vrf, nbr
    @afi, @safi = af
    set_args_keys_default
  end

  def set_args_keys_default
    keys = { :asnum => @asn, :nbr => @nbr, :afi => @afi, :safi => @safi }
    keys[:vrf] = @vrf unless @vrf == 'default'
    @get_args = @set_args = keys
  end

  def set_args_keys(hash = {})
    set_args_keys_default
    @set_args = @get_args.merge!(hash) unless hash.empty?
  end

  def create
    set_args_keys(:state => '')
    @@node.config_set('bgp_neighbor', 'af', @set_args)
  end

  def destroy
    set_args_keys(:state => 'no')
    @@node.config_set('bgp_neighbor', 'af', @set_args)
  end

  ########################################################
  #                      PROPERTIES                      #
  ########################################################

  # -----------------------
  # <state> allowas-in <max>
  # Nvgens as True -OR- True with max-occurrences
  def allowas_in_get
    val = @@node.config_get('bgp_nbr_af', 'allowas_in', @get_args)
    return nil if val.nil?
    val = val.shift.split.last.to_i
  end

  def allowas_in
    allowas_in_get.nil? ? false : true
  end

  def allowas_in_max
    val = allowas_in_get
    val = default_allowas_in_max if val.nil? or val.zero? # workaround for CSCuv86255
    val
  end

  def allowas_in_set(state, max = nil)
    set_args_keys(:state => (state ? '' : 'no'), :max => max)
    @@node.config_set('bgp_nbr_af', 'allowas_in', @set_args)
  end

  def default_allowas_in
    @@node.config_get_default('bgp_nbr_af', 'allowas_in')
  end

  def default_allowas_in_max
    @@node.config_get_default('bgp_nbr_af', 'allowas_in_max')
  end

  # -----------------------
  # <state> advertise-map <map1> exist-map <map2>

  # Returns True, False, or ['<map1>', '<map2>']
  def advertise_map_exist
    arr = @@node.config_get('bgp_nbr_af', 'advertise_map_exist', @get_args)
    return default_advertise_map_exist if arr.nil?
    arr.shift
  end

  def advertise_map_exist=(arr)
    if arr.empty?
      state = 'no'
      map1, map2 = advertise_map_exist
    else
      map1, map2 = arr
    end
    set_args_keys(:state => state, :map1 => map1, :map2 => map2)
    @@node.config_set('bgp_nbr_af', 'advertise_map_exist', @set_args)
  end

  def default_advertise_map_exist
    @@node.config_get_default('bgp_nbr_af', 'advertise_map_exist')
  end

  # -----------------------
  # <state> advertise-map <map1> non-exist-map <map2> }

  # Returns True, False, or ['<map1>', '<map2>']
  def advertise_map_non_exist
    arr = @@node.config_get('bgp_nbr_af', 'advertise_map_non_exist', @get_args)
    return default_advertise_map_non_exist if arr.nil?
    arr.shift
  end

  def advertise_map_non_exist=(arr)
    if arr.empty?
      state = 'no'
      map1, map2 = advertise_map_non_exist
    else
      map1, map2 = arr
    end
    set_args_keys(:state => state, :map1 => map1, :map2 => map2)
    @@node.config_set('bgp_nbr_af', 'advertise_map_non_exist', @set_args)
  end

  def default_advertise_map_non_exist
    @@node.config_get_default('bgp_nbr_af', 'advertise_map_non_exist')
  end

  # -----------------------
  # <state> as-override
  def as_override
    state = @@node.config_get('bgp_nbr_af', 'as_override', @get_args)
    state ? true : false
  end

  def as_override=(state)
    set_args_keys(:state => (state ? '' : 'no'))
    @@node.config_set('bgp_nbr_af', 'as_override', @set_args)
  end

  def default_as_override
    @@node.config_get_default('bgp_nbr_af', 'as_override')
  end

  # -----------------------
  # <state> capability additional-paths receive <disable>
  # Nvgens as True -OR- True with 'disable' keyword
  def cap_add_paths_receive_get
    val = @@node.config_get('bgp_nbr_af', 'cap_add_paths_receive', @get_args)
    return nil if val.nil?
    (val.shift[/disable/]) ? 'disable' : true
  end

  def cap_add_paths_receive
    cap_add_paths_receive_get.nil? ? false : true
  end

  def cap_add_paths_receive_disable
    cap_add_paths_receive_get.to_s[/disable/] ? true : false
  end

  def cap_add_paths_receive_set(state, disable = false)
    set_args_keys(:state => (state ? '' : 'no'),
                  :disable => (disable ? 'disable' : ''))
    @@node.config_set('bgp_nbr_af', 'cap_add_paths_receive', @set_args)
  end

  def default_cap_add_paths_receive
    @@node.config_get_default('bgp_nbr_af', 'cap_add_paths_receive')
  end

  def default_cap_add_paths_receive_disable
    @@node.config_get_default('bgp_nbr_af', 'cap_add_paths_receive_disable')
  end

  # -----------------------
  # <state> capability additional-paths send <disable>
  # Nvgens as True -OR- True with 'disable' keyword
  def cap_add_paths_send_get
    val = @@node.config_get('bgp_nbr_af', 'cap_add_paths_send', @get_args)
    return nil if val.nil?
    (val.shift[/disable/]) ? 'disable' : true
  end

  def cap_add_paths_send
    cap_add_paths_send_get.nil? ? false : true
  end

  def cap_add_paths_send_disable
    cap_add_paths_send_get.to_s[/disable/] ? true : false
  end

  def cap_add_paths_send_set(state, disable = false)
    set_args_keys(:state => (state ? '' : 'no'),
                  :disable => (disable ? 'disable' : ''))
    @@node.config_set('bgp_nbr_af', 'cap_add_paths_send', @set_args)
  end

  def default_cap_add_paths_send
    @@node.config_get_default('bgp_nbr_af', 'cap_add_paths_send')
  end

  def default_cap_add_paths_send_disable
    @@node.config_get_default('bgp_nbr_af', 'cap_add_paths_send_disable')
  end

  # -----------------------
  # <state> default-originate [ route-map <map> ]
  # Nvgens as True -OR- True with 'route-map <map>'
  def default_originate
    val = @@node.config_get('bgp_nbr_af', 'default_originate', @get_args)
    return default_default_originate if val.nil?
    val = val.shift
    val = (val[/route-map/]) ? val.split.last : true
  end

  def default_originate=(val)
    state = (val == false) ? 'no' : ''
    val = (val.is_a? String and not val.empty?) ? "route-map #{val}" : ''
    set_args_keys(:state => state, :map => val)
    @@node.config_set('bgp_nbr_af', 'default_originate', @set_args)
  end

  def default_default_originate
    @@node.config_get_default('bgp_nbr_af', 'default_originate')
  end

  # -----------------------
  # <state> disable-peer-as-check
  def disable_peer_as_check
    state = @@node.config_get('bgp_nbr_af', 'disable_peer_as_check', @get_args)
    state ? true : default_disable_peer_as_check
  end

  def disable_peer_as_check=(state)
    set_args_keys(:state => (state ? '' : 'no'))
    @@node.config_set('bgp_nbr_af', 'disable_peer_as_check', @set_args)
  end

  def default_disable_peer_as_check
    @@node.config_get_default('bgp_nbr_af', 'disable_peer_as_check')
  end

  # -----------------------
  # <state> filter-list <str> in
  def filter_list_in
    str = @@node.config_get('bgp_nbr_af', 'filter_list_in', @get_args)
    return default_filter_list_in if str.nil?
    str.shift.strip
  end

  def filter_list_in=(str)
    str.strip! unless str.nil?
    if str == default_filter_list_in
      state = 'no'
      # Current filter list name is required for removal
      str = filter_list_in
    end
    set_args_keys(:state => state, :str => str)
    @@node.config_set('bgp_nbr_af', 'filter_list_in', @set_args)
  end

  def default_filter_list_in
    @@node.config_get_default('bgp_nbr_af', 'filter_list_in')
  end

  # -----------------------
  # <state> filter-list <str> out
  def filter_list_out
    str = @@node.config_get('bgp_nbr_af', 'filter_list_out', @get_args)
    return default_filter_list_out if str.nil?
    str.shift.strip
  end

  def filter_list_out=(str)
    str.strip! unless str.nil?
    if str == default_filter_list_out
      state = 'no'
      # Current filter list name is required for removal
      str = filter_list_out
    end
    set_args_keys(:state => state, :str => str)
    @@node.config_set('bgp_nbr_af', 'filter_list_out', @set_args)
  end

  def default_filter_list_out
    @@node.config_get_default('bgp_nbr_af', 'filter_list_out')
  end

  # -----------------------
  # <state> maximum-prefix <limit> <threshold> <opt>
  #
  # <threshold> : optional
  # <opt> : optional = [ restart <interval> | warning-only ]
  #
  def max_prefix_get
    str = @@node.config_get('bgp_nbr_af', 'max_prefix', @get_args)
    return nil if str.nil?

    regexp = Regexp.new('maximum-prefix (?<limit>\d+)' +
                        ' *(?<threshold>\d+)?' +
                        ' *(?<opt>restart|warning-only)?' +
                        ' *(?<interval>\d+)?')
    regexp.match(str.shift)
  end

  def max_prefix_set(limit, threshold = nil, opt = nil)
    state = limit.nil? ? 'no' : ''
    unless opt.nil?
      opt = opt.respond_to?(:to_i) ? "restart #{opt}" : 'warning-only'
    end
    set_args_keys(:state => (limit.nil? ? 'no' : ''), :limit => limit,
                  :threshold => threshold, :opt => opt)
    @@node.config_set('bgp_nbr_af', 'max_prefix', @set_args)
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
    @@node.config_get_default('bgp_nbr_af', 'max_prefix_limit')
  end

  def default_max_prefix_interval
    @@node.config_get_default('bgp_nbr_af', 'max_prefix_interval')
  end

  def default_max_prefix_threshold
    @@node.config_get_default('bgp_nbr_af', 'max_prefix_threshold')
  end

  def default_max_prefix_warning
    @@node.config_get_default('bgp_nbr_af', 'max_prefix_warning')
  end

  # -----------------------
  # <state> next-hop-self
  def next_hop_self
    state = @@node.config_get('bgp_nbr_af', 'next_hop_self', @get_args)
    state ? true : false
  end

  def next_hop_self=(state)
    set_args_keys(:state => (state ? '' : 'no'))
    @@node.config_set('bgp_nbr_af', 'next_hop_self', @set_args)
  end

  def default_next_hop_self
    @@node.config_get_default('bgp_nbr_af', 'next_hop_self')
  end

  # -----------------------
  # <state> next-hop-third-party
  def next_hop_third_party
    state = @@node.config_get('bgp_nbr_af', 'next_hop_third_party', @get_args)
    state ? true : false
  end

  def next_hop_third_party=(state)
    set_args_keys(:state => (state ? '' : 'no'))
    @@node.config_set('bgp_nbr_af', 'next_hop_third_party', @set_args)
  end

  def default_next_hop_third_party
    @@node.config_get_default('bgp_nbr_af', 'next_hop_third_party')
  end

  # -----------------------
  # <state route-reflector-client
  def route_reflector_client
    state = @@node.config_get('bgp_nbr_af', 'route_reflector_client', @get_args)
    state ? true : false
  end

  def route_reflector_client=(state)
    set_args_keys(:state => (state ? '' : 'no'))
    @@node.config_set('bgp_nbr_af', 'route_reflector_client', @set_args)
  end

  def default_route_reflector_client
    @@node.config_get_default('bgp_nbr_af', 'route_reflector_client')
  end

  # -----------------------
  # <state> send-community [ both | extended | standard ]
  # NOTE: 'standard' is default and does not nvgen -CSCuv86246
  # Returns: none, both, extended, or standard
  def send_community
    val = @@node.config_get('bgp_nbr_af', 'send_community', @get_args)
    return default_send_community if val.nil?
    val = val.shift.split.last
    return 'standard' if val[/send-community/]  # Workaround for CSCuv86246
    val
  end

  def send_community=(val)
    state, val = 'no', 'both' if val == 'none'
    if val[/extended|standard/]
      case send_community
      when /both/
        state = 'no'
        # Unset the opposite property
        val = val[/extended/] ? 'standard' : 'extended'

      when /extended|standard/
        # This is an additive property therefore remove the entire command
        # when switching from: ext <--> std
        set_args_keys(:state => 'no', :attr => 'both')
        @@node.config_set('bgp_nbr_af', 'send_community', @set_args)
        state = ''
      end
    end
    set_args_keys(:state => state, :attr => val)
    @@node.config_set('bgp_nbr_af', 'send_community', @set_args)
  end

  def default_send_community
    @@node.config_get_default('bgp_nbr_af', 'send_community')
  end

  # -----------------------
  # <state> soft-reconfiguration inbound <always>
  # Nvgens as True -OR- True with 'always' keyword
  def soft_reconfiguration_in_get
    val = @@node.config_get('bgp_nbr_af', 'soft_reconfiguration_in', @get_args)
    return nil if val.nil?
    (val.shift[/always/]) ? 'always' : true
  end

  def soft_reconfiguration_in
    soft_reconfiguration_in_get.nil? ? false : true
  end

  def soft_reconfiguration_in_always
    soft_reconfiguration_in_get.to_s[/always/] ? true : false
  end

  def soft_reconfiguration_in_set(state, always = false)
    set_args_keys(:state => (state ? '' : 'no'),
                  :always => (always ? 'always' : ''))
    @@node.config_set('bgp_nbr_af', 'soft_reconfiguration_in', @set_args)
  end

  def default_soft_reconfiguration_in
    @@node.config_get_default('bgp_nbr_af', 'soft_reconfiguration_in')
  end

  def default_soft_reconfiguration_in_always
    @@node.config_get_default('bgp_nbr_af', 'soft_reconfiguration_in_always')
  end

  # -----------------------
  # <state> soo <str>
  def soo
    str = @@node.config_get('bgp_nbr_af', 'soo', @get_args)
    return default_soo if str.nil?
    str.shift.strip
  end

  def soo=(str)
    str.strip! unless str.nil?
    state, str = 'no', soo if str == default_soo
    set_args_keys(:state => state, :str => str)
    @@node.config_set('bgp_nbr_af', 'soo', @set_args)
  end

  def default_soo
    @@node.config_get_default('bgp_nbr_af', 'soo')
  end

  # -----------------------
  # <state> suppress-inactive
  def suppress_inactive
    state = @@node.config_get('bgp_nbr_af', 'suppress_inactive', @get_args)
    state ? true : false
  end

  def suppress_inactive=(state)
    set_args_keys(:state => (state ? '' : 'no'))
    @@node.config_set('bgp_nbr_af', 'suppress_inactive', @set_args)
  end

  def default_suppress_inactive
    @@node.config_get_default('bgp_nbr_af', 'suppress_inactive')
  end

  # -----------------------
  # <state> unsuppress-map <str>
  def unsuppress_map
    str = @@node.config_get('bgp_nbr_af', 'unsuppress_map', @get_args)
    return default_unsuppress_map if str.nil?
    str.shift.strip
  end

  def unsuppress_map=(str)
    str.strip! unless str.nil?
    if str == default_unsuppress_map
      state = 'no'
      str = unsuppress_map
    end
    set_args_keys(:state => state, :str => str)
    @@node.config_set('bgp_nbr_af', 'unsuppress_map', @set_args)
  end

  def default_unsuppress_map
    @@node.config_get_default('bgp_nbr_af', 'unsuppress_map')
  end

  # -----------------------
  # <state> weight <int>
  def weight
    int = @@node.config_get('bgp_nbr_af', 'weight', @get_args)
    int.nil? ? default_weight : int.shift
  end

  def weight=(int)
    state, int = 'no', '' if int == default_weight
    set_args_keys(:state => state, :int => int)
    @@node.config_set('bgp_nbr_af', 'weight', @set_args)
  end

  def default_weight
    @@node.config_get_default('bgp_nbr_af', 'weight')
  end
end
end
