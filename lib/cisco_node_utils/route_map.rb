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
    def extract_value(prop, prefix=nil)
      prefix = prop if prefix.nil?
      match = match_ipv4_multicast_get

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
                          ' *(?<rp>rp \S+)?')
      regexp.match(str)
    end

    def match_ipv4_multicast_src_addr
      val = extract_value('src', 'source')
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
      val = extract_value('grp', 'group')
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
      val = extract_value('grp_range_start', 'group-range')
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
      val = extract_value('grp_range_end', 'to')
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
      val = extract_value('rp')
      return default_match_ipv4_multicast_rp_addr if val.nil?
      val
    end

    def match_ipv4_multicast_rp_addr=(rp_addr)
      attach_prefix(rp_addr, :rp)
    end

    def default_match_ipv4_multicast_rp_addr
      config_get_default('route_map', 'match_ipv4_multicast_rp_addr')
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
      set_args_keys_default
      set_args_keys(attrs)
      [:match_ipv4_multicast_src_addr,
       :match_ipv4_multicast_group_addr,
       :match_ipv4_multicast_group_range_begin_addr,
       :match_ipv4_multicast_group_range_end_addr,
       :match_ipv4_multicast_rp_addr,
       :match_ipv4_multicast_enable,
      ].each do |p|
        attrs[p] = '' if attrs[p].nil?
        send(p.to_s + '=', attrs[p])
      end
      @get_args = @set_args
      config_set('route_map', 'match_ipv4_multicast', @set_args)
      set_args_keys_default
    end
  end # class
end # module
