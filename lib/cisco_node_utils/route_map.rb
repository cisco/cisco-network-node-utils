#
# January 2017, Sai Chintalapudi
#
# Copyright (c) 2017 Cisco and/or its affiliates.
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
  # node_utils class for route_map
  class RouteMap < NodeUtil
    attr_reader :name, :action, :seq

    def initialize(map_name, sequence, action, instantiate=true)
      fail TypeError unless map_name.is_a?(String)
      fail ArgumentError unless action[/permit|deny/]
      @name = map_name
      @seq = sequence
      @action = action

      set_args_keys_default
      create if instantiate
    end

    def self.maps
      hash = {}
      maps = config_get('route_map', 'all_route_maps')
      return hash if maps.nil?
      maps.each do |name, action, seq|
        hash[name] ||= {}
        hash[name][seq] ||= {}
        hash[name][seq][action] = RouteMap.new(name, seq, action, false)
      end
      hash
    end

    # Helper method to delete @set_args hash keys
    def set_args_keys_default
      @set_args = { name: @name, action: @action, seq: @seq }
      @get_args = @set_args
    end

    # rubocop:disable Style/AccessorMethodName
    def set_args_keys(hash={})
      set_args_keys_default
      @set_args = @get_args.merge!(hash) unless hash.empty?
    end

    # Create one route map instance
    def create
      config_set('route_map', 'create', @set_args)
    end

    def destroy
      config_set('route_map', 'destroy', @set_args)
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    # match as-number 12, 13-23, 45
    def match_as_number
      arr = []
      match_array = config_get('route_map', 'match_as_number', @get_args)
      match_array.each do |line|
        next if line.include?('as-path-list')
        arr = line.strip.split(', ')
      end
      arr
    end

    def match_as_number=(list)
      carr = match_as_number
      cstr = ''
      carr.each do |elem|
        cstr = cstr.concat(elem + ', ')
      end
      unless cstr.empty?
        cstr.chomp!(', ')
        set_args_keys(state: 'no', num: cstr)
        # reset the current config
        config_set('route_map', 'match_as_number', @set_args)
      end
      nstr = ''
      list.each do |elem|
        nstr = nstr.concat(elem + ', ')
      end
      return if nstr.empty?
      nstr.chomp!(', ')
      set_args_keys(state: '', num: nstr)
      config_set('route_map', 'match_as_number', @set_args)
    end

    def default_match_as_number
      config_get_default('route_map', 'match_as_number')
    end

    # match as-number as-path-list abc xyz
    def match_as_number_as_path_list
      str = config_get('route_map', 'match_as_number_as_path_list', @get_args)
      str.empty? ? default_match_as_number_as_path_list : str.split
    end

    def match_as_number_as_path_list=(list)
      carr = match_as_number_as_path_list
      cstr = ''
      carr.each do |elem|
        cstr = cstr.concat(elem + ' ')
      end
      unless cstr.empty?
        set_args_keys(state: 'no', list: cstr)
        # reset the current config
        config_set('route_map', 'match_as_number_as_path_list', @set_args)
      end
      nstr = ''
      list.each do |elem|
        nstr = nstr.concat(elem + ' ')
      end
      return if nstr.empty?
      set_args_keys(state: '', list: nstr)
      config_set('route_map', 'match_as_number_as_path_list', @set_args)
    end

    def default_match_as_number_as_path_list
      config_get_default('route_map', 'match_as_number_as_path_list')
    end

    def description
      config_get('route_map', 'description', @get_args)
    end

    def description=(val)
      state = val ? '' : 'no'
      desc = val ? val : ''
      set_args_keys(state: state, desc: desc)
      config_set('route_map', 'description', @set_args)
    end

    def default_description
      config_get_default('route_map', 'description')
    end

    # match community public private exact-match
    def match_community
      str = config_get('route_map', 'match_community', @get_args)
      if str.empty?
        val = default_match_community
      else
        val = str.split
        val.delete('exact-match')
      end
      val
    end

    def match_community_set(list, exact)
      carr = match_community
      cstr = ''
      carr.each do |elem|
        cstr = cstr.concat(elem + ' ')
      end
      unless cstr.empty?
        set_args_keys(state: 'no', comm: cstr)
        # reset the current config
        config_set('route_map', 'match_community', @set_args)
      end
      nstr = ''
      list.each do |elem|
        nstr = nstr.concat(elem + ' ')
      end
      return if nstr.empty?
      nstr.concat('exact-match') if exact
      set_args_keys(state: '', comm: nstr)
      config_set('route_map', 'match_community', @set_args)
    end

    def default_match_community
      config_get_default('route_map', 'match_community')
    end

    # match extcommunity public private exact-match
    def match_community_exact_match
      config_get('route_map', 'match_community',
                 @get_args).include?('exact-match')
    end

    def default_match_community_exact_match
      config_get_default('route_map', 'match_community_exact_match')
    end

    def match_ext_community
      str = config_get('route_map', 'match_ext_community', @get_args)
      if str.empty?
        val = default_match_ext_community
      else
        val = str.split
        val.delete('exact-match')
      end
      val
    end

    def match_ext_community_set(list, exact)
      carr = match_ext_community
      cstr = ''
      carr.each do |elem|
        cstr = cstr.concat(elem + ' ')
      end
      unless cstr.empty?
        set_args_keys(state: 'no', comm: cstr)
        # reset the current config
        config_set('route_map', 'match_ext_community', @set_args)
      end
      nstr = ''
      list.each do |elem|
        nstr = nstr.concat(elem + ' ')
      end
      return if nstr.empty?
      nstr.concat('exact-match') if exact
      set_args_keys(state: '', comm: nstr)
      config_set('route_map', 'match_ext_community', @set_args)
    end

    def default_match_ext_community
      config_get_default('route_map', 'match_ext_community')
    end

    def match_ext_community_exact_match
      config_get('route_map', 'match_ext_community',
                 @get_args).include?('exact-match')
    end

    def default_match_ext_community_exact_match
      config_get_default('route_map', 'match_ext_community_exact_match')
    end

    # match interface port-channel1 Null0 (and so on)
    def match_interface
      str = config_get('route_map', 'match_interface', @get_args)
      intf = str.empty? ? default_match_interface : str.split
      # Normalize by downcasing
      intf.map!(&:downcase)
    end

    def match_interface=(list)
      carr = match_interface
      cstr = ''
      carr.each do |elem|
        cstr = cstr.concat(elem + ' ')
      end
      unless cstr.empty?
        set_args_keys(state: 'no', int: cstr)
        # reset the current config
        config_set('route_map', 'match_interface', @set_args)
      end
      nstr = ''
      list.each do |elem|
        nstr = nstr.concat(elem + ' ')
      end
      return if nstr.empty?
      set_args_keys(state: '', int: nstr)
      config_set('route_map', 'match_interface', @set_args)
    end

    def default_match_interface
      config_get_default('route_map', 'match_interface')
    end

    # match tag 11 5 28
    def match_tag
      str = config_get('route_map', 'match_tag', @get_args)
      str.empty? ? default_match_tag : str.split
    end

    def match_tag=(list)
      carr = match_tag
      cstr = ''
      carr.each do |elem|
        cstr = cstr.concat(elem + ' ')
      end
      unless cstr.empty?
        set_args_keys(state: 'no', tag: cstr)
        # reset the current config
        config_set('route_map', 'match_tag', @set_args)
      end
      nstr = ''
      list.each do |elem|
        nstr = nstr.concat(elem + ' ')
      end
      return if nstr.empty?
      set_args_keys(state: '', tag: nstr)
      config_set('route_map', 'match_tag', @set_args)
    end

    def default_match_tag
      config_get_default('route_map', 'match_tag')
    end

    # match source-protocol tcp udp
    def match_src_proto
      str = config_get('route_map', 'match_src_proto', @get_args)
      str.empty? ? default_match_src_proto : str.split
    end

    def match_src_proto=(list)
      carr = match_src_proto
      cstr = ''
      carr.each do |elem|
        cstr = cstr.concat(elem + ' ')
      end
      unless cstr.empty?
        set_args_keys(state: 'no', proto: cstr)
        # reset the current config
        config_set('route_map', 'match_src_proto', @set_args)
      end
      nstr = ''
      list.each do |elem|
        nstr = nstr.concat(elem + ' ')
      end
      return if nstr.empty?
      set_args_keys(state: '', proto: nstr)
      config_set('route_map', 'match_src_proto', @set_args)
    end

    def default_match_src_proto
      config_get_default('route_map', 'match_src_proto')
    end

    def match_ipv4_addr_access_list
      val = default_match_ipv4_addr_access_list
      arr = config_get('route_map', 'match_ipv4_addr_access_list', @get_args)
      if arr
        arr.each do |line|
          next if line.include?('prefix-list')
          val = line.strip
        end
      end
      val
    end

    def match_ipv4_addr_access_list_set(val)
      cval = match_ipv4_addr_access_list
      return if val == cval
      state = val ? '' : 'no'
      al = val ? val : cval
      set_args_keys(state: state, access: al)
      config_set('route_map', 'match_ipv4_addr_access_list', @set_args)
    end

    def default_match_ipv4_addr_access_list
      config_get_default('route_map', 'match_ipv4_addr_access_list')
    end

    # match ip address prefix-list pre1 pre2
    def match_ipv4_addr_prefix_list
      str = config_get('route_map', 'match_ipv4_addr_prefix_list', @get_args)
      str.empty? ? default_match_ipv4_addr_prefix_list : str.split
    end

    def match_ipv4_addr_prefix_list_set(list)
      carr = match_ipv4_addr_prefix_list
      cstr = ''
      carr.each do |elem|
        cstr = cstr.concat(elem + ' ')
      end
      unless cstr.empty?
        set_args_keys(state: 'no', prefix: cstr)
        # reset the current config
        config_set('route_map', 'match_ipv4_addr_prefix_list', @set_args)
      end
      nstr = ''
      list.each do |elem|
        nstr = nstr.concat(elem + ' ')
      end
      return if nstr.empty?
      set_args_keys(state: '', prefix: nstr)
      config_set('route_map', 'match_ipv4_addr_prefix_list', @set_args)
    end

    def default_match_ipv4_addr_prefix_list
      config_get_default('route_map', 'match_ipv4_addr_prefix_list')
    end

    # match ip next-hop prefix-list nhop1 nhop2
    def match_ipv4_next_hop_prefix_list
      str = config_get('route_map', 'match_ipv4_next_hop_prefix_list',
                       @get_args)
      str.empty? ? default_match_ipv4_next_hop_prefix_list : str.split
    end

    def match_ipv4_next_hop_prefix_list=(list)
      carr = match_ipv4_next_hop_prefix_list
      cstr = ''
      carr.each do |elem|
        cstr = cstr.concat(elem + ' ')
      end
      unless cstr.empty?
        set_args_keys(state: 'no', prefix: cstr)
        # reset the current config
        config_set('route_map', 'match_ipv4_next_hop_prefix_list', @set_args)
      end
      nstr = ''
      list.each do |elem|
        nstr = nstr.concat(elem + ' ')
      end
      return if nstr.empty?
      set_args_keys(state: '', prefix: nstr)
      config_set('route_map', 'match_ipv4_next_hop_prefix_list', @set_args)
    end

    def default_match_ipv4_next_hop_prefix_list
      config_get_default('route_map', 'match_ipv4_next_hop_prefix_list')
    end

    # match ip route-source prefix-list rs1 rs2
    def match_ipv4_route_src_prefix_list
      str = config_get('route_map', 'match_ipv4_route_src_prefix_list',
                       @get_args)
      str.empty? ? default_match_ipv4_route_src_prefix_list : str.split
    end

    def match_ipv4_route_src_prefix_list=(list)
      carr = match_ipv4_route_src_prefix_list
      cstr = ''
      carr.each do |elem|
        cstr = cstr.concat(elem + ' ')
      end
      unless cstr.empty?
        set_args_keys(state: 'no', prefix: cstr)
        # reset the current config
        config_set('route_map', 'match_ipv4_route_src_prefix_list', @set_args)
      end
      nstr = ''
      list.each do |elem|
        nstr = nstr.concat(elem + ' ')
      end
      return if nstr.empty?
      set_args_keys(state: '', prefix: nstr)
      config_set('route_map', 'match_ipv4_route_src_prefix_list', @set_args)
    end

    def default_match_ipv4_route_src_prefix_list
      config_get_default('route_map', 'match_ipv4_route_src_prefix_list')
    end

    # extract value of property from match ip multicast
    def extract_value(type, prop, prefix=nil)
      prefix = prop if prefix.nil?
      match =
        type == 'ipv4' ? match_ipv4_multicast_get : match_ipv6_multicast_get

      # matching not found
      return nil if match.nil? # no matching found

      # property not defined for matching
      return nil unless match.names.include?(prop)

      # extract and return value that follows prefix + <space>
      regexp = Regexp.new("#{Regexp.escape(prefix)} (?<extracted>.*)")
      value_match = regexp.match(match[prop])
      return nil if value_match.nil?
      value_match[:extracted]
    end

    # prepend property name prefix/keyword to value
    def attach_prefix(val, prop, prefix=nil)
      prefix = prop.to_s if prefix.nil?
      @set_args[prop] = val.to_s.empty? ? val : "#{prefix} #{val}"
    end

    # match ip multicast source 242.1.1.1/32 group 239.2.2.2/32 rp 242.1.1.1/32
    #                    rp-type ASM
    # match ip multicast source 242.1.1.1/32 group-range
    #                    239.1.1.1 to 239.2.2.2 rp 242.1.1.1/32 rp-type Bidir
    def match_ipv4_multicast_get
      str = config_get('route_map', 'match_ipv4_multicast', @get_args)
      return nil if str.nil?
      regexp = Regexp.new('match ip multicast *(?<src>source \S+)?'\
                          ' *(?<grp>group \S+)?'\
                          ' *(?<grp_range_start>group-range \S+)?'\
                          ' *(?<grp_range_end>to \S+)?'\
                          ' *(?<rp>rp \S+)?'\
                          ' *(?<rp_type>rp-type \S+)?')
      regexp.match(str)
    end

    def match_ipv4_multicast_src_addr
      val = extract_value('ipv4', 'src', 'source')
      return default_match_ipv4_multicast_src_addr if val.nil?
      val
    end

    def match_ipv4_multicast_src_addr=(src_addr)
      attach_prefix(src_addr, :source)
    end

    def default_match_ipv4_multicast_src_addr
      config_get_default('route_map', 'match_ipv4_multicast_src_addr')
    end

    def match_ipv4_multicast_group_addr
      val = extract_value('ipv4', 'grp', 'group')
      return default_match_ipv4_multicast_group_addr if val.nil?
      val
    end

    def match_ipv4_multicast_group_addr=(grp_addr)
      attach_prefix(grp_addr, :group)
    end

    def default_match_ipv4_multicast_group_addr
      config_get_default('route_map', 'match_ipv4_multicast_group_addr')
    end

    def match_ipv4_multicast_group_range_begin_addr
      val = extract_value('ipv4', 'grp_range_start', 'group-range')
      return default_match_ipv4_multicast_group_range_begin_addr if val.nil?
      val
    end

    def match_ipv4_multicast_group_range_begin_addr=(begin_addr)
      attach_prefix(begin_addr, :group_range, :'group-range')
    end

    def default_match_ipv4_multicast_group_range_begin_addr
      config_get_default('route_map',
                         'match_ipv4_multicast_group_range_begin_addr')
    end

    def match_ipv4_multicast_group_range_end_addr
      val = extract_value('ipv4', 'grp_range_end', 'to')
      return default_match_ipv4_multicast_group_range_end_addr if val.nil?
      val
    end

    def match_ipv4_multicast_group_range_end_addr=(end_addr)
      attach_prefix(end_addr, :to)
    end

    def default_match_ipv4_multicast_group_range_end_addr
      config_get_default('route_map',
                         'match_ipv4_multicast_group_range_end_addr')
    end

    def match_ipv4_multicast_rp_addr
      val = extract_value('ipv4', 'rp')
      return default_match_ipv4_multicast_rp_addr if val.nil?
      val
    end

    def match_ipv4_multicast_rp_addr=(rp_addr)
      attach_prefix(rp_addr, :rp)
    end

    def default_match_ipv4_multicast_rp_addr
      config_get_default('route_map', 'match_ipv4_multicast_rp_addr')
    end

    def match_ipv4_multicast_rp_type
      val = extract_value('ipv4', 'rp_type', 'rp-type')
      return default_match_ipv4_multicast_rp_type if val.nil?
      val
    end

    def match_ipv4_multicast_rp_type=(type)
      attach_prefix(type, :rp_type, :'rp-type')
    end

    def default_match_ipv4_multicast_rp_type
      config_get_default('route_map', 'match_ipv4_multicast_rp_type')
    end

    def match_ipv4_multicast_enable
      match_ipv4_multicast_get.nil? ? default_match_ipv4_multicast_enable : true
    end

    def match_ipv4_multicast_enable=(enable)
      @set_args[:state] = enable ? '' : 'no'
    end

    def default_match_ipv4_multicast_enable
      config_get_default('route_map', 'match_ipv4_multicast_enable')
    end

    def match_ipv4_multicast_set(attrs)
      set_args_keys(attrs)
      [:match_ipv4_multicast_src_addr,
       :match_ipv4_multicast_group_addr,
       :match_ipv4_multicast_group_range_begin_addr,
       :match_ipv4_multicast_group_range_end_addr,
       :match_ipv4_multicast_rp_addr,
       :match_ipv4_multicast_rp_type,
       :match_ipv4_multicast_enable,
      ].each do |p|
        attrs[p] = '' if attrs[p].nil?
        send(p.to_s + '=', attrs[p])
      end
      @get_args = @set_args
      config_set('route_map', 'match_ipv4_multicast', @set_args)
    end

    def match_ipv6_addr_access_list
      val = default_match_ipv6_addr_access_list
      arr = config_get('route_map', 'match_ipv6_addr_access_list', @get_args)
      if arr
        arr.each do |line|
          next if line.include?('prefix-list')
          val = line.strip
        end
      end
      val
    end

    def match_ipv6_addr_access_list_set(val)
      cval = match_ipv6_addr_access_list
      return if val == cval
      state = val ? '' : 'no'
      al = val ? val : cval
      set_args_keys(state: state, access: al)
      config_set('route_map', 'match_ipv6_addr_access_list', @set_args)
    end

    def default_match_ipv6_addr_access_list
      config_get_default('route_map', 'match_ipv6_addr_access_list')
    end

    def match_ip_addr_access_list(v4, v6)
      match_ipv4_addr_access_list_set(default_match_ipv4_addr_access_list)
      match_ipv6_addr_access_list_set(default_match_ipv6_addr_access_list)
      match_ipv4_addr_access_list_set(v4)
      match_ipv6_addr_access_list_set(v6)
    end

    def match_ipv6_addr_prefix_list
      str = config_get('route_map', 'match_ipv6_addr_prefix_list', @get_args)
      str.empty? ? default_match_ipv6_addr_prefix_list : str.split
    end

    def match_ipv6_addr_prefix_list_set(list)
      carr = match_ipv6_addr_prefix_list
      cstr = ''
      carr.each do |elem|
        cstr = cstr.concat(elem + ' ')
      end
      unless cstr.empty?
        set_args_keys(state: 'no', prefix: cstr)
        # reset the current config
        config_set('route_map', 'match_ipv6_addr_prefix_list', @set_args)
      end
      nstr = ''
      list.each do |elem|
        nstr = nstr.concat(elem + ' ')
      end
      return if nstr.empty?
      set_args_keys(state: '', prefix: nstr)
      config_set('route_map', 'match_ipv6_addr_prefix_list', @set_args)
    end

    def default_match_ipv6_addr_prefix_list
      config_get_default('route_map', 'match_ipv6_addr_prefix_list')
    end

    def match_ip_addr_prefix_list(v4, v6)
      match_ipv4_addr_prefix_list_set(default_match_ipv4_addr_prefix_list)
      match_ipv6_addr_prefix_list_set(default_match_ipv6_addr_prefix_list)
      match_ipv4_addr_prefix_list_set(v4)
      match_ipv6_addr_prefix_list_set(v6)
    end

    def match_ipv6_next_hop_prefix_list
      str = config_get('route_map', 'match_ipv6_next_hop_prefix_list',
                       @get_args)
      str.empty? ? default_match_ipv6_next_hop_prefix_list : str.split
    end

    def match_ipv6_next_hop_prefix_list=(list)
      carr = match_ipv6_next_hop_prefix_list
      cstr = ''
      carr.each do |elem|
        cstr = cstr.concat(elem + ' ')
      end
      unless cstr.empty?
        set_args_keys(state: 'no', prefix: cstr)
        # reset the current config
        config_set('route_map', 'match_ipv6_next_hop_prefix_list', @set_args)
      end
      nstr = ''
      list.each do |elem|
        nstr = nstr.concat(elem + ' ')
      end
      return if nstr.empty?
      set_args_keys(state: '', prefix: nstr)
      config_set('route_map', 'match_ipv6_next_hop_prefix_list', @set_args)
    end

    def default_match_ipv6_next_hop_prefix_list
      config_get_default('route_map', 'match_ipv6_next_hop_prefix_list')
    end

    def match_ipv6_route_src_prefix_list
      str = config_get('route_map', 'match_ipv6_route_src_prefix_list',
                       @get_args)
      str.empty? ? default_match_ipv6_route_src_prefix_list : str.split
    end

    def match_ipv6_route_src_prefix_list=(list)
      carr = match_ipv6_route_src_prefix_list
      cstr = ''
      carr.each do |elem|
        cstr = cstr.concat(elem + ' ')
      end
      unless cstr.empty?
        set_args_keys(state: 'no', prefix: cstr)
        # reset the current config
        config_set('route_map', 'match_ipv6_route_src_prefix_list', @set_args)
      end
      nstr = ''
      list.each do |elem|
        nstr = nstr.concat(elem + ' ')
      end
      return if nstr.empty?
      set_args_keys(state: '', prefix: nstr)
      config_set('route_map', 'match_ipv6_route_src_prefix_list', @set_args)
    end

    def default_match_ipv6_route_src_prefix_list
      config_get_default('route_map', 'match_ipv6_route_src_prefix_list')
    end

    def match_ipv6_multicast_get
      str = config_get('route_map', 'match_ipv6_multicast', @get_args)
      return nil if str.nil?
      regexp = Regexp.new('match ipv6 multicast *(?<src>source \S+)?'\
                          ' *(?<grp>group \S+)?'\
                          ' *(?<grp_range_start>group-range \S+)?'\
                          ' *(?<grp_range_end>to \S+)?'\
                          ' *(?<rp>rp \S+)?'\
                          ' *(?<rp_type>rp-type \S+)?')
      regexp.match(str)
    end

    def match_ipv6_multicast_src_addr
      val = extract_value('ipv6', 'src', 'source')
      return default_match_ipv6_multicast_src_addr if val.nil?
      val
    end

    def match_ipv6_multicast_src_addr=(src_addr)
      attach_prefix(src_addr, :source)
    end

    def default_match_ipv6_multicast_src_addr
      config_get_default('route_map', 'match_ipv6_multicast_src_addr')
    end

    def match_ipv6_multicast_group_addr
      val = extract_value('ipv6', 'grp', 'group')
      return default_match_ipv6_multicast_group_addr if val.nil?
      val
    end

    def match_ipv6_multicast_group_addr=(grp_addr)
      attach_prefix(grp_addr, :group)
    end

    def default_match_ipv6_multicast_group_addr
      config_get_default('route_map', 'match_ipv6_multicast_group_addr')
    end

    def match_ipv6_multicast_group_range_begin_addr
      val = extract_value('ipv6', 'grp_range_start', 'group-range')
      return default_match_ipv6_multicast_group_range_begin_addr if val.nil?
      val
    end

    def match_ipv6_multicast_group_range_begin_addr=(begin_addr)
      attach_prefix(begin_addr, :group_range, :'group-range')
    end

    def default_match_ipv6_multicast_group_range_begin_addr
      config_get_default('route_map',
                         'match_ipv6_multicast_group_range_begin_addr')
    end

    def match_ipv6_multicast_group_range_end_addr
      val = extract_value('ipv6', 'grp_range_end', 'to')
      return default_match_ipv6_multicast_group_range_end_addr if val.nil?
      val
    end

    def match_ipv6_multicast_group_range_end_addr=(end_addr)
      attach_prefix(end_addr, :to)
    end

    def default_match_ipv6_multicast_group_range_end_addr
      config_get_default('route_map',
                         'match_ipv6_multicast_group_range_end_addr')
    end

    def match_ipv6_multicast_rp_addr
      val = extract_value('ipv6', 'rp')
      return default_match_ipv6_multicast_rp_addr if val.nil?
      val
    end

    def match_ipv6_multicast_rp_addr=(rp_addr)
      attach_prefix(rp_addr, :rp)
    end

    def default_match_ipv6_multicast_rp_addr
      config_get_default('route_map', 'match_ipv6_multicast_rp_addr')
    end

    def match_ipv6_multicast_rp_type
      val = extract_value('ipv6', 'rp_type', 'rp-type')
      return default_match_ipv6_multicast_rp_type if val.nil?
      val
    end

    def match_ipv6_multicast_rp_type=(type)
      attach_prefix(type, :rp_type, :'rp-type')
    end

    def default_match_ipv6_multicast_rp_type
      config_get_default('route_map', 'match_ipv6_multicast_rp_type')
    end

    def match_ipv6_multicast_enable
      match_ipv6_multicast_get.nil? ? default_match_ipv6_multicast_enable : true
    end

    def match_ipv6_multicast_enable=(enable)
      @set_args[:state] = enable ? '' : 'no'
    end

    def default_match_ipv6_multicast_enable
      config_get_default('route_map', 'match_ipv6_multicast_enable')
    end

    def match_ipv6_multicast_set(attrs)
      set_args_keys(attrs)
      [:match_ipv6_multicast_src_addr,
       :match_ipv6_multicast_group_addr,
       :match_ipv6_multicast_group_range_begin_addr,
       :match_ipv6_multicast_group_range_end_addr,
       :match_ipv6_multicast_rp_addr,
       :match_ipv6_multicast_rp_type,
       :match_ipv6_multicast_enable,
      ].each do |p|
        attrs[p] = '' if attrs[p].nil?
        send(p.to_s + '=', attrs[p])
      end
      @get_args = @set_args
      config_set('route_map', 'match_ipv6_multicast', @set_args)
    end

    # match metric 1 8 224 +- 9 23 5 +- 8 6
    def match_metric
      str = config_get('route_map', 'match_metric', @get_args)
      return default_match_metric if str.empty?
      rarr = []
      larr = []
      metrics = str.split
      deviation = false
      metrics.each do |metric|
        deviation = true if metric == '+-'
        if !larr.empty? && !deviation
          larr << '0'
          rarr << larr
          larr = []
        end
        next if metric == '+-'
        if !larr.empty? && deviation
          larr << metric
          rarr << larr
          larr = []
          deviation = false
          next
        end
        larr << metric if larr.empty?
      end
      unless larr.empty?
        larr << '0'
        rarr << larr
      end
      rarr
    end

    def match_metric=(list)
      clist = match_metric
      # reset first
      unless clist.empty?
        str = ''
        clist.each do |metric, deviation|
          str.concat(metric + ' ')
          str.concat('+ ' + deviation + ' ') unless deviation == '0'
        end
        set_args_keys(state: 'no', metric: str)
        config_set('route_map', 'match_metric', @set_args)
      end
      return if list.empty?
      str = ''
      list.each do |metric, deviation|
        str.concat(metric + ' ')
        str.concat('+ ' + deviation + ' ') unless deviation == '0'
      end
      set_args_keys(state: '', metric: str)
      config_set('route_map', 'match_metric', @set_args)
    end

    def default_match_metric
      config_get_default('route_map', 'match_metric')
    end

    # match route-type external internal (and so on)
    # or in some platforms
    # match route-type external
    # match route-type internal
    # etc.
    def match_route_type_get
      hash = {}
      hash[:external] = false
      hash[:inter_area] = false
      hash[:internal] = false
      hash[:intra_area] = false
      hash[:level_1] = false
      hash[:level_2] = false
      hash[:local] = false
      hash[:nssa_external] = false
      hash[:type_1] = false
      hash[:type_2] = false
      str = config_get('route_map', 'match_route_type', @get_args)
      return hash if str.nil?
      str = str[0] if str.length == 1
      hash[:external] = true if str.include?('external')
      hash[:inter_area] = true if str.include?('inter-area')
      hash[:internal] = true if str.include?('internal')
      hash[:intra_area] = true if str.include?('intra-area')
      hash[:level_1] = true if str.include?('level-1')
      hash[:level_2] = true if str.include?('level-2')
      hash[:local] = true if str.include?('local')
      hash[:nssa_external] = true if str.include?('nssa-external')
      hash[:type_1] = true if str.include?('type-1')
      hash[:type_2] = true if str.include?('type-2')
      hash
    end

    def match_route_type_set(attrs)
      # reset first
      set_args_keys(
        state:         'no',
        external:      'external',
        inter_area:    'inter-area',
        internal:      'internal',
        intra_area:    'intra-area',
        level_1:       'level-1',
        level_2:       'level-2',
        local:         'local',
        nssa_external: 'nssa-external',
        type_1:        'type-1',
        type_2:        'type-2')
      config_set('route_map', 'match_route_type', @set_args)

      to_set = false
      set_args_keys(attrs)
      [:match_route_type_external,
       :match_route_type_inter_area,
       :match_route_type_internal,
       :match_route_type_intra_area,
       :match_route_type_level_1,
       :match_route_type_level_2,
       :match_route_type_local,
       :match_route_type_nssa_external,
       :match_route_type_type_1,
       :match_route_type_type_2,
      ].each do |p|
        attrs[p] = false if attrs[p].nil?
        send(p.to_s + '=', attrs[p])
        to_set = true if attrs[p] && !to_set
      end
      return unless to_set
      @set_args[:state] = ''
      @get_args = @set_args
      config_set('route_map', 'match_route_type', @set_args)
    end

    def match_route_type_external
      hash = match_route_type_get
      hash[:external]
    end

    def match_route_type_external=(val)
      @set_args[:external] = val ? 'external' : ''
    end

    def default_match_route_type_external
      config_get_default('route_map', 'match_route_type_external')
    end

    def match_route_type_inter_area
      hash = match_route_type_get
      hash[:inter_area]
    end

    def match_route_type_inter_area=(val)
      @set_args[:inter_area] = val ? 'inter-area' : ''
    end

    def default_match_route_type_inter_area
      config_get_default('route_map', 'match_route_type_inter_area')
    end

    def match_route_type_internal
      hash = match_route_type_get
      hash[:internal]
    end

    def match_route_type_internal=(val)
      @set_args[:internal] = val ? 'internal' : ''
    end

    def default_match_route_type_internal
      config_get_default('route_map', 'match_route_type_internal')
    end

    def match_route_type_intra_area
      hash = match_route_type_get
      hash[:intra_area]
    end

    def match_route_type_intra_area=(val)
      @set_args[:intra_area] = val ? 'intra-area' : ''
    end

    def default_match_route_type_intra_area
      config_get_default('route_map', 'match_route_type_intra_area')
    end

    def match_route_type_level_1
      hash = match_route_type_get
      hash[:level_1]
    end

    def match_route_type_level_1=(val)
      @set_args[:level_1] = val ? 'level-1' : ''
    end

    def default_match_route_type_level_1
      config_get_default('route_map', 'match_route_type_level_1')
    end

    def match_route_type_level_2
      hash = match_route_type_get
      hash[:level_2]
    end

    def match_route_type_level_2=(val)
      @set_args[:level_2] = val ? 'level-2' : ''
    end

    def default_match_route_type_level_2
      config_get_default('route_map', 'match_route_type_level_2')
    end

    def match_route_type_local
      hash = match_route_type_get
      hash[:local]
    end

    def match_route_type_local=(val)
      @set_args[:local] = val ? 'local' : ''
    end

    def default_match_route_type_local
      config_get_default('route_map', 'match_route_type_local')
    end

    def match_route_type_nssa_external
      hash = match_route_type_get
      hash[:nssa_external]
    end

    def match_route_type_nssa_external=(val)
      @set_args[:nssa_external] = val ? 'nssa-external' : ''
    end

    def default_match_route_type_nssa_external
      config_get_default('route_map', 'match_route_type_nssa_external')
    end

    def match_route_type_type_1
      hash = match_route_type_get
      hash[:type_1]
    end

    def match_route_type_type_1=(val)
      @set_args[:type_1] = val ? 'type-1' : ''
    end

    def default_match_route_type_type_1
      config_get_default('route_map', 'match_route_type_type_1')
    end

    def match_route_type_type_2
      hash = match_route_type_get
      hash[:type_2]
    end

    def match_route_type_type_2=(val)
      @set_args[:type_2] = val ? 'type-2' : ''
    end

    def default_match_route_type_type_2
      config_get_default('route_map', 'match_route_type_type_2')
    end

    # match ospf-area 10 7
    def match_ospf_area
      str = config_get('route_map', 'match_ospf_area', @get_args)
      return if str.nil?
      str.empty? ? default_match_ospf_area : str.split
    end

    def match_ospf_area=(list)
      carr = match_ospf_area
      config_set('route_map', 'match_ospf_area', @set_args) if carr.nil?
      cstr = ''
      carr.each do |elem|
        cstr = cstr.concat(elem + ' ')
      end
      unless cstr.empty?
        set_args_keys(state: 'no', area: cstr)
        # reset the current config
        config_set('route_map', 'match_ospf_area', @set_args)
      end
      nstr = ''
      list.each do |elem|
        nstr = nstr.concat(elem + ' ')
      end
      return if nstr.empty?
      set_args_keys(state: '', area: nstr)
      config_set('route_map', 'match_ospf_area', @set_args)
    end

    def default_match_ospf_area
      config_get_default('route_map', 'match_ospf_area')
    end

    # match mac-list m1 m2
    def match_mac_list
      str = config_get('route_map', 'match_mac_list', @get_args)
      return if str.nil?
      str.empty? ? default_match_mac_list : str.split
    end

    def match_mac_list=(list)
      carr = match_mac_list
      config_set('route_map', 'match_mac_list', @set_args) if carr.nil?
      cstr = ''
      carr.each do |elem|
        cstr = cstr.concat(elem + ' ')
      end
      unless cstr.empty?
        set_args_keys(state: 'no', mac: cstr)
        # reset the current config
        config_set('route_map', 'match_mac_list', @set_args)
      end
      nstr = ''
      list.each do |elem|
        nstr = nstr.concat(elem + ' ')
      end
      return if nstr.empty?
      set_args_keys(state: '', mac: nstr)
      config_set('route_map', 'match_mac_list', @set_args)
    end

    def default_match_mac_list
      config_get_default('route_map', 'match_mac_list')
    end

    # match length 45 300
    def match_length
      config_get('route_map', 'match_length', @get_args)
    end

    def match_length=(array)
      if array.empty?
        set_args_keys(state: 'no', min: '', max: '')
      else
        set_args_keys(state: '', min: array[0], max: array[1])
      end
      config_set('route_map', 'match_length', @set_args)
    end

    def default_match_length
      config_get_default('route_map', 'match_length')
    end

    def match_vlan
      ret = config_get('route_map', 'match_vlan', @get_args)
      ret.strip if ret
    end

    def match_vlan=(val)
      cval = match_vlan
      # reset first
      unless cval.nil? || cval.empty?
        set_args_keys(state: 'no', range: cval)
        config_set('route_map', 'match_vlan', @set_args)
      end
      return if val.empty?
      set_args_keys(state: '', range: val)
      config_set('route_map', 'match_vlan', @set_args)
    end

    def default_match_vlan
      config_get_default('route_map', 'match_vlan')
    end

    # match evpn route-type 1
    # match evpn route-type 2 all
    # match evpn route-type 2 mac-ip
    # match evpn route-type 2 mac-only
    # match evpn route-type 3 etc.
    def match_evpn_route_type_get
      arr = config_get('route_map', 'match_evpn_route_type', @get_args)
      return nil if arr.nil?
      hash = {}
      hash[:type1] = false
      hash[:type3] = false
      hash[:type4] = false
      hash[:type5] = false
      hash[:type6] = false
      hash[:type_all] = false
      hash[:type2_all] = false
      hash[:type2_mac_ip] = false
      hash[:type2_mac_only] = false
      return hash if arr.empty?
      hash[:type1] = true if arr.include?('1')
      hash[:type3] = true if arr.include?('3')
      hash[:type4] = true if arr.include?('4')
      hash[:type5] = true if arr.include?('5')
      hash[:type6] = true if arr.include?('6')
      hash[:type_all] = true if arr.include?('all')
      hash[:type2_all] = true if arr.include?('2 all')
      hash[:type2_mac_ip] = true if arr.include?('2 mac-ip')
      hash[:type2_mac_only] = true if arr.include?('2 mac-only')
      hash
    end

    def match_evpn_route_type_1
      hash = match_evpn_route_type_get
      hash.nil? ? nil : hash[:type1]
    end

    def match_evpn_route_type_1=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state, type: '1')
      config_set('route_map', 'match_evpn_route_type', @set_args)
    end

    def default_match_evpn_route_type_1
      config_get_default('route_map', 'match_evpn_route_type_1')
    end

    def match_evpn_route_type_3
      hash = match_evpn_route_type_get
      hash.nil? ? nil : hash[:type3]
    end

    def match_evpn_route_type_3=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state, type: '3')
      config_set('route_map', 'match_evpn_route_type', @set_args)
    end

    def default_match_evpn_route_type_3
      config_get_default('route_map', 'match_evpn_route_type_3')
    end

    def match_evpn_route_type_4
      hash = match_evpn_route_type_get
      hash.nil? ? nil : hash[:type4]
    end

    def match_evpn_route_type_4=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state, type: '4')
      config_set('route_map', 'match_evpn_route_type', @set_args)
    end

    def default_match_evpn_route_type_4
      config_get_default('route_map', 'match_evpn_route_type_4')
    end

    def match_evpn_route_type_5
      hash = match_evpn_route_type_get
      hash.nil? ? nil : hash[:type5]
    end

    def match_evpn_route_type_5=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state, type: '5')
      config_set('route_map', 'match_evpn_route_type', @set_args)
    end

    def default_match_evpn_route_type_5
      config_get_default('route_map', 'match_evpn_route_type_5')
    end

    def match_evpn_route_type_6
      hash = match_evpn_route_type_get
      hash.nil? ? nil : hash[:type6]
    end

    def match_evpn_route_type_6=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state, type: '6')
      config_set('route_map', 'match_evpn_route_type', @set_args)
    end

    def default_match_evpn_route_type_6
      config_get_default('route_map', 'match_evpn_route_type_6')
    end

    def match_evpn_route_type_all
      hash = match_evpn_route_type_get
      hash.nil? ? nil : hash[:type_all]
    end

    def match_evpn_route_type_all=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state, type: 'all')
      config_set('route_map', 'match_evpn_route_type', @set_args)
    end

    def default_match_evpn_route_type_all
      config_get_default('route_map', 'match_evpn_route_type_all')
    end

    def match_evpn_route_type_2_all
      hash = match_evpn_route_type_get
      hash.nil? ? nil : hash[:type2_all]
    end

    def match_evpn_route_type_2_all=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state, type: '2 all')
      config_set('route_map', 'match_evpn_route_type', @set_args)
    end

    def default_match_evpn_route_type_2_all
      config_get_default('route_map', 'match_evpn_route_type_2_all')
    end

    def match_evpn_route_type_2_mac_ip
      hash = match_evpn_route_type_get
      hash.nil? ? nil : hash[:type2_mac_ip]
    end

    def match_evpn_route_type_2_mac_ip=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state, type: '2 mac-ip')
      config_set('route_map', 'match_evpn_route_type', @set_args)
    end

    def default_match_evpn_route_type_2_mac_ip
      config_get_default('route_map', 'match_evpn_route_type_2_mac_ip')
    end

    def match_evpn_route_type_2_mac_only
      hash = match_evpn_route_type_get
      hash.nil? ? nil : hash[:type2_mac_only]
    end

    def match_evpn_route_type_2_mac_only=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state, type: '2 mac-only')
      config_set('route_map', 'match_evpn_route_type', @set_args)
    end

    def default_match_evpn_route_type_2_mac_only
      config_get_default('route_map', 'match_evpn_route_type_2_mac_only')
    end

    def set_comm_list
      config_get('route_map', 'set_comm_list', @get_args)
    end

    def set_comm_list=(val)
      state = val ? '' : 'no'
      list = val ? val : set_comm_list
      set_args_keys(state: state, list: list)
      config_set('route_map', 'set_comm_list', @set_args)
    end

    def default_set_comm_list
      config_get_default('route_map', 'set_comm_list')
    end

    def set_extcomm_list
      config_get('route_map', 'set_extcomm_list', @get_args)
    end

    def set_extcomm_list=(val)
      state = val ? '' : 'no'
      list = val ? val : set_extcomm_list
      set_args_keys(state: state, list: list)
      config_set('route_map', 'set_extcomm_list', @set_args)
    end

    def default_set_extcomm_list
      config_get_default('route_map', 'set_extcomm_list')
    end

    def set_forwarding_addr
      config_get('route_map', 'set_forwarding_addr', @get_args)
    end

    def set_forwarding_addr=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state)
      config_set('route_map', 'set_forwarding_addr', @set_args)
    end

    def default_set_forwarding_addr
      config_get_default('route_map', 'set_forwarding_addr')
    end

    def set_level
      config_get('route_map', 'set_level', @get_args)
    end

    def set_level=(val)
      state = val ? '' : 'no'
      level = val ? val : ''
      set_args_keys(state: state, level: level)
      config_set('route_map', 'set_level', @set_args)
    end

    def default_set_level
      config_get_default('route_map', 'set_level')
    end

    def set_local_preference
      config_get('route_map', 'set_local_preference', @get_args)
    end

    def set_local_preference=(val)
      state = val ? '' : 'no'
      pref = val ? val : ''
      set_args_keys(state: state, pref: pref)
      config_set('route_map', 'set_local_preference', @set_args)
    end

    def default_set_local_preference
      config_get_default('route_map', 'set_local_preference')
    end

    def set_metric_type
      config_get('route_map', 'set_metric_type', @get_args)
    end

    def set_metric_type=(val)
      state = val ? '' : 'no'
      type = val ? val : ''
      set_args_keys(state: state, type: type)
      config_set('route_map', 'set_metric_type', @set_args)
    end

    def default_set_metric_type
      config_get_default('route_map', 'set_metric_type')
    end

    def set_nssa_only
      config_get('route_map', 'set_nssa_only', @get_args)
    end

    def set_nssa_only=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state)
      config_set('route_map', 'set_nssa_only', @set_args)
    end

    def default_set_nssa_only
      config_get_default('route_map', 'set_nssa_only')
    end

    def set_origin
      config_get('route_map', 'set_origin', @get_args)
    end

    def set_origin=(val)
      state = val ? '' : 'no'
      origin = val ? val : ''
      set_args_keys(state: state, origin: origin)
      config_set('route_map', 'set_origin', @set_args)
    end

    def default_set_origin
      config_get_default('route_map', 'set_origin')
    end

    def set_path_selection
      config_get('route_map', 'set_path_selection', @get_args)
    end

    def set_path_selection=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state)
      config_set('route_map', 'set_path_selection', @set_args)
    end

    def default_set_path_selection
      config_get_default('route_map', 'set_path_selection')
    end

    def set_tag
      config_get('route_map', 'set_tag', @get_args)
    end

    def set_tag=(val)
      state = val ? '' : 'no'
      tag = val ? val : ''
      set_args_keys(state: state, tag: tag)
      config_set('route_map', 'set_tag', @set_args)
    end

    def default_set_tag
      config_get_default('route_map', 'set_tag')
    end

    def set_vrf
      vrf = config_get('route_map', 'set_vrf', @get_args)
      vrf == 'default' ? 'default_vrf' : vrf
    end

    def set_vrf=(val)
      state = val ? '' : 'no'
      vrf = val ? val : ''
      vrf = vrf == 'default_vrf' ? 'default' : vrf
      set_args_keys(state: state, vrf: vrf)
      config_set('route_map', 'set_vrf', @set_args)
    end

    def default_set_vrf
      config_get_default('route_map', 'set_vrf')
    end

    def set_weight
      config_get('route_map', 'set_weight', @get_args)
    end

    def set_weight=(val)
      state = val ? '' : 'no'
      weight = val ? val : ''
      set_args_keys(state: state, weight: weight)
      config_set('route_map', 'set_weight', @set_args)
    end

    def default_set_weight
      config_get_default('route_map', 'set_weight')
    end

    # set metric 44 55 66 77 88
    # set metric +33
    def set_metric_get
      hash = {}
      hash[:additive] = false
      hash[:bandwidth] = false
      hash[:delay] = false
      hash[:reliability] = false
      hash[:effective_bandwidth] = false
      hash[:mtu] = false
      str = config_get('route_map', 'set_metric', @get_args)
      return hash if str.nil?
      arr = str.split
      hash[:additive] = true if arr[0].include?('+')
      hash[:bandwidth] = arr[0].delete('+').to_i
      return hash if arr.size == 1
      hash[:delay] = arr[1].to_i
      hash[:reliability] = arr[2].to_i
      hash[:effective_bandwidth] = arr[3].to_i
      hash[:mtu] = arr[4].to_i
      hash
    end

    def set_metric_set(plus, bndw, del, reliability, eff_bw, mtu)
      state = bndw ? '' : 'no'
      additive = plus ? '+' : ''
      bw = bndw ? bndw : ''
      delay = del ? del : ''
      rel = reliability ? reliability : ''
      eff = eff_bw ? eff_bw : ''
      lmtu = mtu ? mtu : ''
      set_args_keys(state: state, additive: additive, bw: bw, delay: delay,
                    rel: rel, eff: eff, mtu: lmtu)
      config_set('route_map', 'set_metric', @set_args)
    end

    def set_metric_additive
      hash = set_metric_get
      hash[:additive]
    end

    def default_set_metric_additive
      config_get_default('route_map', 'set_metric_additive')
    end

    def set_metric_bandwidth
      hash = set_metric_get
      hash[:bandwidth]
    end

    def default_set_metric_bandwidth
      config_get_default('route_map', 'set_metric_bandwidth')
    end

    def set_metric_delay
      hash = set_metric_get
      hash[:delay]
    end

    def default_set_metric_delay
      config_get_default('route_map', 'set_metric_delay')
    end

    def set_metric_reliability
      hash = set_metric_get
      hash[:reliability]
    end

    def default_set_metric_reliability
      config_get_default('route_map', 'set_metric_reliability')
    end

    def set_metric_effective_bandwidth
      hash = set_metric_get
      hash[:effective_bandwidth]
    end

    def default_set_metric_effective_bandwidth
      config_get_default('route_map', 'set_metric_effective_bandwidth')
    end

    def set_metric_mtu
      hash = set_metric_get
      hash[:mtu]
    end

    def default_set_metric_mtu
      config_get_default('route_map', 'set_metric_mtu')
    end

    # set dampening 6 22 44 55
    def set_dampening_get
      hash = {}
      hash[:half_life] = false
      hash[:reuse] = false
      hash[:suppress] = false
      hash[:max] = false
      str = config_get('route_map', 'set_dampening', @get_args)
      return hash if str.nil?
      arr = str.split
      hash[:half_life] = arr[0].to_i
      hash[:reuse] = arr[1].to_i
      hash[:suppress] = arr[2].to_i
      hash[:max] = arr[3].to_i
      hash
    end

    def set_dampening_set(half_life, reuse, supp, md)
      if half_life
        set_args_keys(state: '', hl: half_life, reuse: reuse, supp: supp,
                      max: md)
      else
        set_args_keys(state: 'no', hl: '', reuse: '', supp: '', max: '')
      end
      config_set('route_map', 'set_dampening', @set_args)
    end

    def set_dampening_half_life
      hash = set_dampening_get
      hash[:half_life]
    end

    def default_set_dampening_half_life
      config_get_default('route_map', 'set_dampening_half_life')
    end

    def set_dampening_reuse
      hash = set_dampening_get
      hash[:reuse]
    end

    def default_set_dampening_reuse
      config_get_default('route_map', 'set_dampening_reuse')
    end

    def set_dampening_suppress
      hash = set_dampening_get
      hash[:suppress]
    end

    def default_set_dampening_suppress
      config_get_default('route_map', 'set_dampening_suppress')
    end

    def set_dampening_max_duation
      hash = set_dampening_get
      hash[:max]
    end

    def default_set_dampening_max_duation
      config_get_default('route_map', 'set_dampening_max_duation')
    end

    # set distance 1 2 3
    # set distance 1 2
    # set distance 1
    def set_distance_get
      hash = {}
      hash[:igp] = false
      hash[:internal] = false
      hash[:local] = false
      str = config_get('route_map', 'set_distance', @get_args)
      return hash if str.nil?
      arr = str.split
      hash[:igp] = arr[0].to_i
      hash[:internal] = arr[1].to_i if arr[1]
      hash[:local] = arr[2].to_i if arr[2]
      hash
    end

    def set_distance_set(igp, internal, local)
      state = igp ? '' : 'no'
      igp_ebgp = igp ? igp : ''
      int = internal ? internal : ''
      loc = local ? local : ''
      set_args_keys(state: state, igp: igp_ebgp, internal: int, local: loc)
      config_set('route_map', 'set_distance', @set_args)
    end

    def set_distance_igp_ebgp
      hash = set_distance_get
      hash[:igp]
    end

    def default_set_distance_igp_ebgp
      config_get_default('route_map', 'set_distance_igp_ebgp')
    end

    def set_distance_local
      hash = set_distance_get
      hash[:local]
    end

    def default_set_distance_local
      config_get_default('route_map', 'set_distance_local')
    end

    def set_distance_internal
      hash = set_distance_get
      hash[:internal]
    end

    def default_set_distance_internal
      config_get_default('route_map', 'set_distance_internal')
    end

    def set_as_path_prepend_last_as
      config_get('route_map', 'set_as_path_prepend_last_as', @get_args)
    end

    def set_as_path_prepend_last_as=(val)
      state = val ? '' : 'no'
      as = val ? val : ''
      set_args_keys(state: state, as: as)
      config_set('route_map', 'set_as_path_prepend_last_as', @set_args)
    end

    def default_set_as_path_prepend_last_as
      config_get_default('route_map', 'set_as_path_prepend_last_as')
    end

    def set_as_path_tag
      config_get('route_map', 'set_as_path_tag', @get_args)
    end

    def set_as_path_tag=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state)
      config_set('route_map', 'set_as_path_tag', @set_args)
    end

    def default_set_as_path_tag
      config_get_default('route_map', 'set_as_path_tag')
    end

    # set as-path prepend 55.77 44 33.5
    # set as-path prepend last-as 1
    def set_as_path_prepend
      arr = []
      match = config_get('route_map', 'set_as_path_prepend', @get_args)
      if arr
        match.each do |line|
          next if line.include?('last-as')
          arr = line.strip.split
        end
      end
      arr
    end

    def set_as_path_prepend=(list)
      nstr = ''
      list.each do |elem|
        nstr = nstr.concat(elem + ' ')
      end
      state = nstr.empty? ? 'no' : ''
      set_args_keys(state: state, asnum: nstr)
      config_set('route_map', 'set_as_path_prepend', @set_args)
    end

    def default_set_as_path_prepend
      config_get_default('route_map', 'set_as_path_prepend')
    end

    # set interface Null0
    def set_interface
      str = config_get('route_map', 'set_interface', @get_args)
      str ? str.strip : default_set_interface
    end

    def set_interface_set(val)
      cint = set_interface
      return if cint == val
      state = val ? '' : 'no'
      int = val ? val : cint
      set_args_keys(state: state, int: int)
      config_set('route_map', 'set_interface', @set_args)
    end

    def default_set_interface
      config_get_default('route_map', 'set_interface')
    end

    def set_ipv4_prefix
      config_get('route_map', 'set_ipv4_prefix', @get_args)
    end

    def set_ipv4_prefix=(val)
      state = val ? '' : 'no'
      pf = val ? val : set_ipv4_prefix
      set_args_keys(state: state, pf: pf)
      config_set('route_map', 'set_ipv4_prefix', @set_args)
    end

    def default_set_ipv4_prefix
      config_get_default('route_map', 'set_ipv4_prefix')
    end

    def set_ipv4_precedence
      config_get('route_map', 'set_ipv4_precedence', @get_args)
    end

    def set_ipv4_precedence_set(val)
      state = val ? '' : 'no'
      pre = val ? val : ''
      set_args_keys(state: state, pre: pre)
      config_set('route_map', 'set_ipv4_precedence', @set_args)
    end

    def default_set_ipv4_precedence
      config_get_default('route_map', 'set_ipv4_precedence')
    end

    # set ip default next-hop 1.1.1.1 2.2.2.2 3.3.3.3
    def set_ipv4_default_next_hop
      str = config_get('route_map', 'set_ipv4_default_next_hop', @get_args)
      return if str.nil?
      if str.empty?
        val = default_set_ipv4_default_next_hop
      else
        val = str.split
        val.delete('load-share')
      end
      val
    end

    def set_ipv4_def_next_hop_set(list, share)
      carr = set_ipv4_default_next_hop
      fail Cisco::UnsupportedError.new(
        'route_map',
        'set_ipv4_default_next_hop') if carr.nil?
      cstr = ''
      carr.each do |elem|
        cstr = cstr.concat(elem + ' ')
      end
      cstr.concat('load-share')
      set_args_keys(state: 'no', nh: cstr)
      # reset the current config
      config_set('route_map', 'set_ipv4_default_next_hop', @set_args)
      nstr = ''
      list.each do |elem|
        nstr = nstr.concat(elem + ' ')
      end
      nstr.concat('load-share') if share
      return if nstr.empty?
      set_args_keys(state: '', nh: nstr)
      config_set('route_map', 'set_ipv4_default_next_hop', @set_args)
    end

    def default_set_ipv4_default_next_hop
      config_get_default('route_map', 'set_ipv4_default_next_hop')
    end

    # set ip default next-hop 1.1.1.1 2.2.2.2 3.3.3.3 load-share
    # set ip default next-hop load-share
    def set_ipv4_default_next_hop_load_share
      match = config_get('route_map', 'set_ipv4_default_next_hop', @get_args)
      return if match.nil?
      match.include?('load-share')
    end

    def default_set_ipv4_default_next_hop_load_share
      config_get_default('route_map', 'set_ipv4_default_next_hop_load_share')
    end

    # set ip next-hop 1.1.1.1 2.2.2.2 3.3.3.3
    def set_ipv4_next_hop
      arr = config_get('route_map', 'set_ipv4_next_hop', @get_args)
      val = default_set_ipv4_next_hop
      arr.each do |str|
        next if str.empty?
        next if str.include?('peer-address')
        next if str.include?('unchanged')
        next if str.include?('redist-unchanged')
        val = str.split
        val.delete('load-share')
      end
      val
    end

    def set_ipv4_next_hop_set(list, share=false)
      carr = set_ipv4_next_hop
      cstr = ''
      carr.each do |elem|
        cstr = cstr.concat(elem + ' ')
      end
      cstr.concat('load-share') unless default_set_ipv4_next_hop_load_share.nil?
      set_args_keys(state: 'no', nh: cstr)
      # reset the current config
      config_set('route_map', 'set_ipv4_next_hop', @set_args) unless
        cstr.empty?
      nstr = ''
      list.each do |elem|
        nstr = nstr.concat(elem + ' ')
      end
      nstr.concat('load-share') if share
      return if nstr.empty?
      set_args_keys(state: '', nh: nstr)
      config_set('route_map', 'set_ipv4_next_hop', @set_args)
    end

    def default_set_ipv4_next_hop
      config_get_default('route_map', 'set_ipv4_next_hop')
    end

    # set ip next-hop 1.1.1.1 2.2.2.2 3.3.3.3 load-share
    # set ip next-hop load-share
    def set_ipv4_next_hop_load_share
      arr = config_get('route_map', 'set_ipv4_next_hop', @get_args)
      val = default_set_ipv4_next_hop_load_share
      arr.each do |str|
        next if str.empty?
        return true if str.include?('load-share')
      end
      val
    end

    def default_set_ipv4_next_hop_load_share
      config_get_default('route_map', 'set_ipv4_next_hop_load_share')
    end

    def set_ipv4_next_hop_peer_addr
      config_get('route_map', 'set_ipv4_next_hop_peer_addr', @get_args)
    end

    def set_ipv4_next_hop_peer_addr_set(val)
      state = val ? '' : 'no'
      set_args_keys(state: state)
      config_set('route_map', 'set_ipv4_next_hop_peer_addr', @set_args)
    end

    def default_set_ipv4_next_hop_peer_addr
      config_get_default('route_map', 'set_ipv4_next_hop_peer_addr')
    end

    def set_ipv4_next_hop_redist
      config_get('route_map', 'set_ipv4_next_hop_redist', @get_args)
    end

    def set_ipv4_next_hop_redist_set(val)
      state = val ? '' : 'no'
      set_args_keys(state: state)
      config_set('route_map', 'set_ipv4_next_hop_redist', @set_args)
    end

    def default_set_ipv4_next_hop_redist
      config_get_default('route_map', 'set_ipv4_next_hop_redist')
    end

    def set_ipv4_next_hop_unchanged
      config_get('route_map', 'set_ipv4_next_hop_unchanged', @get_args)
    end

    def set_ipv4_next_hop_unchanged_set(val)
      state = val ? '' : 'no'
      set_args_keys(state: state)
      config_set('route_map', 'set_ipv4_next_hop_unchanged', @set_args)
    end

    def default_set_ipv4_next_hop_unchanged
      config_get_default('route_map', 'set_ipv4_next_hop_unchanged')
    end

    def set_ipv6_prefix
      config_get('route_map', 'set_ipv6_prefix', @get_args)
    end

    def set_ipv6_prefix=(val)
      state = val ? '' : 'no'
      pf = val ? val : set_ipv6_prefix
      set_args_keys(state: state, pf: pf)
      config_set('route_map', 'set_ipv6_prefix', @set_args)
    end

    def default_set_ipv6_prefix
      config_get_default('route_map', 'set_ipv6_prefix')
    end

    def set_ipv6_precedence
      config_get('route_map', 'set_ipv6_precedence', @get_args)
    end

    def set_ipv6_precedence_set(val)
      state = val ? '' : 'no'
      pre = val ? val : ''
      set_args_keys(state: state, pre: pre)
      config_set('route_map', 'set_ipv6_precedence', @set_args)
    end

    def default_set_ipv6_precedence
      config_get_default('route_map', 'set_ipv6_precedence')
    end

    def set_ip_precedence(v4, v6)
      set_ipv4_precedence_set(default_set_ipv4_precedence)
      set_ipv6_precedence_set(default_set_ipv6_precedence)
      set_ipv4_precedence_set(v4)
      set_ipv6_precedence_set(v6)
    end

    # set ipv6 default next-hop 1.1.1.1 2.2.2.2 3.3.3.3
    def set_ipv6_default_next_hop
      str = config_get('route_map', 'set_ipv6_default_next_hop', @get_args)
      return if str.nil?
      if str.empty?
        val = default_set_ipv6_default_next_hop
      else
        val = str.split
        val.delete('load-share')
      end
      val
    end

    def set_ipv6_def_next_hop_set(list, share)
      carr = set_ipv6_default_next_hop
      fail Cisco::UnsupportedError.new(
        'route_map',
        'set_ipv6_default_next_hop') if carr.nil?
      cstr = ''
      carr.each do |elem|
        cstr = cstr.concat(elem + ' ')
      end
      cstr.concat('load-share')
      set_args_keys(state: 'no', nh: cstr)
      # reset the current config
      config_set('route_map', 'set_ipv6_default_next_hop', @set_args)
      nstr = ''
      list.each do |elem|
        nstr = nstr.concat(elem + ' ')
      end
      nstr.concat('load-share') if share
      return if nstr.empty?
      set_args_keys(state: '', nh: nstr)
      config_set('route_map', 'set_ipv6_default_next_hop', @set_args)
    end

    def default_set_ipv6_default_next_hop
      config_get_default('route_map', 'set_ipv6_default_next_hop')
    end

    # set ipv6 default next-hop 1.1.1.1 2.2.2.2 3.3.3.3 load-share
    # set ipv6 default next-hop load-share
    def set_ipv6_default_next_hop_load_share
      match = config_get('route_map', 'set_ipv6_default_next_hop', @get_args)
      return if match.nil?
      match.include?('load-share')
    end

    def default_set_ipv6_default_next_hop_load_share
      config_get_default('route_map', 'set_ipv6_default_next_hop_load_share')
    end

    # set ipv6 next-hop 1.1.1.1 2.2.2.2 3.3.3.3
    def set_ipv6_next_hop
      arr = config_get('route_map', 'set_ipv6_next_hop', @get_args)
      val = default_set_ipv6_next_hop
      arr.each do |str|
        next if str.empty?
        next if str.include?('peer-address')
        next if str.include?('unchanged')
        next if str.include?('redist-unchanged')
        val = str.split
        val.delete('load-share')
      end
      val
    end

    def set_ipv6_next_hop_set(list, share=false)
      carr = set_ipv6_next_hop
      cstr = ''
      carr.each do |elem|
        cstr = cstr.concat(elem + ' ')
      end
      cstr.concat('load-share') unless default_set_ipv6_next_hop_load_share.nil?
      set_args_keys(state: 'no', nh: cstr)
      # reset the current config
      config_set('route_map', 'set_ipv6_next_hop', @set_args) unless
        cstr.empty?
      nstr = ''
      list.each do |elem|
        nstr = nstr.concat(elem + ' ')
      end
      nstr.concat('load-share') if share
      return if nstr.empty?
      set_args_keys(state: '', nh: nstr)
      config_set('route_map', 'set_ipv6_next_hop', @set_args)
    end

    def default_set_ipv6_next_hop
      config_get_default('route_map', 'set_ipv6_next_hop')
    end

    # set ipv6 default next-hop 1.1.1.1 2.2.2.2 3.3.3.3 load-share
    # set ipv6 default next-hop load-share
    def set_ipv6_next_hop_load_share
      arr = config_get('route_map', 'set_ipv6_next_hop', @get_args)
      val = default_set_ipv6_next_hop_load_share
      arr.each do |str|
        next if str.empty?
        return true if str.include?('load-share')
      end
      val
    end

    def default_set_ipv6_next_hop_load_share
      config_get_default('route_map', 'set_ipv6_next_hop_load_share')
    end

    def set_ipv6_next_hop_peer_addr
      config_get('route_map', 'set_ipv6_next_hop_peer_addr', @get_args)
    end

    def set_ipv6_next_hop_peer_addr_set(val)
      state = val ? '' : 'no'
      set_args_keys(state: state)
      config_set('route_map', 'set_ipv6_next_hop_peer_addr', @set_args)
    end

    def default_set_ipv6_next_hop_peer_addr
      config_get_default('route_map', 'set_ipv6_next_hop_peer_addr')
    end

    def set_ipv6_next_hop_redist
      config_get('route_map', 'set_ipv6_next_hop_redist', @get_args)
    end

    def set_ipv6_next_hop_redist_set(val)
      state = val ? '' : 'no'
      set_args_keys(state: state)
      config_set('route_map', 'set_ipv6_next_hop_redist', @set_args)
    end

    def default_set_ipv6_next_hop_redist
      config_get_default('route_map', 'set_ipv6_next_hop_redist')
    end

    def set_ipv6_next_hop_unchanged
      config_get('route_map', 'set_ipv6_next_hop_unchanged', @get_args)
    end

    def set_ipv6_next_hop_unchanged_set(val)
      state = val ? '' : 'no'
      set_args_keys(state: state)
      config_set('route_map', 'set_ipv6_next_hop_unchanged', @set_args)
    end

    def default_set_ipv6_next_hop_unchanged
      config_get_default('route_map', 'set_ipv6_next_hop_unchanged')
    end

    def set_community_additive
      str = config_get('route_map', 'set_community', @get_args)
      add = false
      return add if str.nil?
      add = true if str.include?('additive') || str == 'set community '
      add
    end

    def default_set_community_additive
      config_get_default('route_map', 'set_community_additive')
    end

    def set_community_internet
      str = config_get('route_map', 'set_community', @get_args)
      str.nil? ? false : str.include?('internet')
    end

    def default_set_community_internet
      config_get_default('route_map', 'set_community_internet')
    end

    def set_community_local_as
      str = config_get('route_map', 'set_community', @get_args)
      str.nil? ? false : str.include?('local-AS')
    end

    def default_set_community_local_as
      config_get_default('route_map', 'set_community_local_as')
    end

    def set_community_no_advtertise
      str = config_get('route_map', 'set_community', @get_args)
      str.nil? ? false : str.include?('no-advertise')
    end

    def default_set_community_no_advtertise
      config_get_default('route_map', 'set_community_no_advtertise')
    end

    def set_community_no_export
      str = config_get('route_map', 'set_community', @get_args)
      str.nil? ? false : str.include?('no-export')
    end

    def default_set_community_no_export
      config_get_default('route_map', 'set_community_no_export')
    end

    def set_community_none
      str = config_get('route_map', 'set_community', @get_args)
      str.nil? ? false : str.include?('none')
    end

    def default_set_community_none
      config_get_default('route_map', 'set_community_none')
    end

    def set_community_asn
      str = config_get('route_map', 'set_community', @get_args)
      return default_set_community_asn if str.nil? || !str.include?(':')
      str.sub!('set community', '')
      str.sub!('internet', '')
      str.sub!('additive', '')
      str.sub!('local-AS', '')
      str.sub!('no-export', '')
      str.sub!('no-advertise', '')
      str.split
    end

    def default_set_community_asn
      config_get_default('route_map', 'set_community_asn')
    end

    # set community none
    # set community (if only additive is configured)
    # set internet 11:22 22:33 local-AS no-advertise no-export additive
    # and combinations of the above
    def set_community_set(none, noadv, noexp, add, local, inter, asn)
      str = ''
      # reset first
      set_args_keys(state: 'no', string: str)
      config_set('route_map', 'set_community', @set_args)
      return unless none || noadv || noexp || add ||
                    local || inter || !asn.empty?
      str.concat('internet ') if inter
      asn.each do |elem|
        str.concat(elem + ' ')
      end
      str.concat('no-export ') if noexp
      str.concat('no-advertise ') if noadv
      str.concat('local-AS ') if local
      str.concat('additive ') if add
      str.concat('none') if none
      set_args_keys(state: '', string: str)
      config_set('route_map', 'set_community', @set_args)
    end

    def set_extcommunity_4bytes_additive
      str = config_get('route_map', 'set_extcommunity_4bytes', @get_args)
      str.nil? ? false : str.include?('additive')
    end

    def default_set_extcommunity_4bytes_additive
      config_get_default('route_map', 'set_extcommunity_4bytes_additive')
    end

    def set_extcommunity_4bytes_none
      str = config_get('route_map', 'set_extcommunity_4bytes', @get_args)
      str.nil? ? false : str.include?('none')
    end

    def default_set_extcommunity_4bytes_none
      config_get_default('route_map', 'set_extcommunity_4bytes_none')
    end

    def set_extcommunity_4bytes_non_transitive
      str = config_get('route_map', 'set_extcommunity_4bytes', @get_args)
      return default_set_extcommunity_4bytes_non_transitive if
        str.nil? || !str.include?('non-transitive')
      arr = str.split
      ret_arr = []
      index = arr.index('non-transitive')
      while index
        ret_arr << arr[index + 1]
        arr.delete_at(index)
        arr.delete_at(index)
        index = arr.index('non-transitive')
      end
      ret_arr
    end

    def default_set_extcommunity_4bytes_non_transitive
      config_get_default('route_map', 'set_extcommunity_4bytes_non_transitive')
    end

    def set_extcommunity_4bytes_transitive
      str = config_get('route_map', 'set_extcommunity_4bytes', @get_args)
      return default_set_extcommunity_4bytes_transitive if str.nil?
      arr = str.split
      ret_arr = []
      index = arr.index('transitive')
      while index
        ret_arr << arr[index + 1]
        arr.delete_at(index)
        arr.delete_at(index)
        index = arr.index('transitive')
      end
      ret_arr
    end

    def default_set_extcommunity_4bytes_transitive
      config_get_default('route_map', 'set_extcommunity_4bytes_transitive')
    end

    # set extcommunity 4byteas-generic none
    # set extcommunity 4byteas-generic additive
    # set extcommunity 4byteas-generic transitive 11:22 transitive 22:33
    # set extcommunity 4byteas-generic non-transitive 11:22
    # set extcommunity 4byteas-generic transitive 22:33 non-transitive 11:22
    def set_extcommunity_4bytes_set(none, transit, non_transit, add)
      str = ''
      # reset first
      set_args_keys(state: 'no', string: str)
      config_set('route_map', 'set_extcommunity_4bytes', @set_args)
      return unless none || add || !transit.empty? || !non_transit.empty?
      str.concat('none') if none
      transit.each do |elem|
        str.concat('transitive ' + elem + ' ')
      end
      non_transit.each do |elem|
        str.concat('non-transitive ' + elem + ' ')
      end
      str.concat('additive') if add
      set_args_keys(state: '', string: str)
      config_set('route_map', 'set_extcommunity_4bytes', @set_args)
    end

    def set_extcommunity_rt_additive
      str = config_get('route_map', 'set_extcommunity_rt', @get_args)
      str.nil? ? false : str.include?('additive')
    end

    def default_set_extcommunity_rt_additive
      config_get_default('route_map', 'set_extcommunity_rt_additive')
    end

    def set_extcommunity_rt_asn
      str = config_get('route_map', 'set_extcommunity_rt', @get_args)
      return default_set_extcommunity_rt_asn if str.nil?
      str.delete!('additive')
      str.split
    end

    def default_set_extcommunity_rt_asn
      config_get_default('route_map', 'set_extcommunity_rt_asn')
    end

    # set extcommunity rt additive
    # set extcommunity rt 11:22 12.22.22.22:12 123.256:543
    # set extcommunity rt 11:22 12.22.22.22:12 123.256:543 additive
    def set_extcommunity_rt_set(asn, add)
      str = ''
      # reset first
      set_args_keys(state: 'no', string: str)
      config_set('route_map', 'set_extcommunity_rt', @set_args)
      return unless add || !asn.empty?
      asn.each do |elem|
        str.concat(elem + ' ')
      end
      str.concat('additive') if add
      set_args_keys(state: '', string: str)
      config_set('route_map', 'set_extcommunity_rt', @set_args)
    end

    def set_extcommunity_cost_igp
      str = config_get('route_map', 'set_extcommunity_cost', @get_args)
      return default_set_extcommunity_cost_igp if
        str.nil? || !str.include?('igp')
      arr = str.split
      ret_arr = []
      index = arr.index('igp')
      while index
        larr = []
        larr << arr[index + 1]
        larr << arr[index + 2]
        ret_arr << larr
        arr.delete_at(index)
        arr.delete_at(index)
        arr.delete_at(index)
        index = arr.index('igp')
      end
      ret_arr
    end

    def default_set_extcommunity_cost_igp
      config_get_default('route_map', 'set_extcommunity_cost_igp')
    end

    def set_extcommunity_cost_pre_bestpath
      str = config_get('route_map', 'set_extcommunity_cost', @get_args)
      return default_set_extcommunity_cost_pre_bestpath if
        str.nil? || !str.include?('pre-bestpath')
      arr = str.split
      ret_arr = []
      index = arr.index('pre-bestpath')
      while index
        larr = []
        larr << arr[index + 1]
        larr << arr[index + 2]
        ret_arr << larr
        arr.delete_at(index)
        arr.delete_at(index)
        arr.delete_at(index)
        index = arr.index('pre-bestpath')
      end
      ret_arr
    end

    def default_set_extcommunity_cost_pre_bestpath
      config_get_default('route_map', 'set_extcommunity_cost_pre_bestpath')
    end

    def set_extcommunity_cost_device
      config_get('route_map', 'set_extcommunity_cost_device', @get_args)
    end

    # set extcommunity cost igp 0 22 igp 3 23
    # set extcommunity cost pre-bestpath 1 222 pre-bestpath 2 54
    # set extcommunity cost pre-bestpath 1 222 pre-bestpath 2 54 igp 0 22
    def set_extcommunity_cost_set(igp, pre)
      str = ''
      # reset first
      if set_extcommunity_cost_device
        cpre = set_extcommunity_cost_pre_bestpath
        cigp = set_extcommunity_cost_igp
        cpre.each do |id, val|
          str.concat('pre-bestpath ' + id.to_s + ' ' + val.to_s + ' ')
        end
        cigp.each do |id, val|
          str.concat('igp ' + id.to_s + ' ' + val.to_s + ' ')
        end
      end
      set_args_keys(state: 'no', string: str)
      config_set('route_map', 'set_extcommunity_cost', @set_args)
      return if igp.empty? && pre.empty?
      str = ''
      pre.each do |id, val|
        str.concat('pre-bestpath ' + id.to_s + ' ' + val.to_s + ' ')
      end
      igp.each do |id, val|
        str.concat('igp ' + id.to_s + ' ' + val.to_s + ' ')
      end
      set_args_keys(state: '', string: str)
      config_set('route_map', 'set_extcommunity_cost', @set_args)
    end

    def set_ip_next_hop_reset(attrs)
      set_interface_set(default_set_interface)
      v4ls = default_set_ipv4_default_next_hop_load_share
      set_ipv4_def_next_hop_set(default_set_ipv4_default_next_hop, v4ls) unless
                                default_set_ipv4_default_next_hop.nil?
      default_set_ipv4_default_next_hop.nil?
      set_ipv4_next_hop_set(default_set_ipv4_next_hop)
      set_ipv4_next_hop_peer_addr_set(default_set_ipv4_next_hop_peer_addr)
      set_ipv4_next_hop_redist_set(default_set_ipv4_next_hop_redist) unless
        attrs[:v4red].nil?
      set_ipv4_next_hop_unchanged_set(default_set_ipv4_next_hop_unchanged)
      v6ls = default_set_ipv4_default_next_hop_load_share
      set_ipv6_def_next_hop_set(default_set_ipv6_default_next_hop, v6ls) unless
                                default_set_ipv6_default_next_hop.nil?
      set_ipv6_next_hop_set(default_set_ipv6_next_hop)
      set_ipv6_next_hop_peer_addr_set(default_set_ipv6_next_hop_peer_addr)
      set_ipv6_next_hop_redist_set(default_set_ipv6_next_hop_redist) unless
        attrs[:v6red].nil?
      set_ipv6_next_hop_unchanged_set(default_set_ipv6_next_hop_unchanged)
    end

    def set_ip_next_hop_set(attrs)
      set_ip_next_hop_reset(attrs)
      set_interface_set(attrs[:intf])
      set_ipv4_def_next_hop_set(attrs[:v4dnh], attrs[:v4dls]) unless
        default_set_ipv4_default_next_hop.nil?
      set_ipv4_next_hop_set(attrs[:v4nh], attrs[:v4ls])
      set_ipv4_next_hop_peer_addr_set(attrs[:v4peer])
      set_ipv4_next_hop_redist_set(attrs[:v4red]) unless attrs[:v4red].nil?
      set_ipv4_next_hop_unchanged_set(attrs[:v4unc])
      set_ipv6_def_next_hop_set(attrs[:v6dnh], attrs[:v6dls]) unless
        default_set_ipv6_default_next_hop.nil?
      set_ipv6_next_hop_set(attrs[:v6nh], attrs[:v6ls])
      set_ipv6_next_hop_peer_addr_set(attrs[:v6peer])
      set_ipv6_next_hop_redist_set(attrs[:v6red]) unless attrs[:v6red].nil?
      set_ipv6_next_hop_unchanged_set(attrs[:v6unc])
    end
  end # class
end # module
