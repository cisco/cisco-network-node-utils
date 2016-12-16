#
# December 2016, Sai Chintalapudi
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

    def match_ipv4_addr_access_list=(val)
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

    def match_ipv4_addr_prefix_list
      str = config_get('route_map', 'match_ipv4_addr_prefix_list', @get_args)
      str.empty? ? default_match_ipv4_addr_prefix_list : str.split
    end

    def match_ipv4_addr_prefix_list=(list)
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

    def match_ipv6_addr_access_list=(val)
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

    def match_ipv6_addr_prefix_list
      str = config_get('route_map', 'match_ipv6_addr_prefix_list', @get_args)
      str.empty? ? default_match_ipv6_addr_prefix_list : str.split
    end

    def match_ipv6_addr_prefix_list=(list)
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

    def match_ospf_area
      str = config_get('route_map', 'match_ospf_area', @get_args)
      str.empty? ? default_match_ospf_area : str.split
    end

    def match_ospf_area=(list)
      carr = match_ospf_area
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

    def match_mac_list
      str = config_get('route_map', 'match_mac_list', @get_args)
      str.empty? ? default_match_mac_list : str.split
    end

    def match_mac_list=(list)
      carr = match_mac_list
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
      config_get('route_map', 'match_vlan', @get_args).strip
    end

    def match_vlan=(val)
      cval = match_vlan
      # reset first
      unless cval.empty?
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

    def match_evpn_route_type_get
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
      arr = config_get('route_map', 'match_evpn_route_type', @get_args)
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
      hash[:type1]
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
      hash[:type3]
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
      hash[:type4]
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
      hash[:type5]
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
      hash[:type6]
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
      hash[:type_all]
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
      hash[:type2_all]
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
      hash[:type2_mac_ip]
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
      hash[:type2_mac_only]
    end

    def match_evpn_route_type_2_mac_only=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state, type: '2 mac-only')
      config_set('route_map', 'match_evpn_route_type', @set_args)
    end

    def default_match_evpn_route_type_2_mac_only
      config_get_default('route_map', 'match_evpn_route_type_2_mac_only')
    end
  end # class
end # module
