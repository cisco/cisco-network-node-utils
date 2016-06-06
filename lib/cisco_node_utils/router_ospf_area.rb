#
# NXAPI implementation of Router OSPF Area class
#
# June 2016, Sai Chintalapudi
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

require 'ipaddr'
require_relative 'node_util'
require_relative 'router_ospf'
require_relative 'router_ospf_vrf'

module Cisco
  # node_utils class for ospf_area
  class RouterOspfArea < NodeUtil
    attr_reader :router, :vrf, :area_id

    def initialize(ospf_router, vrf_name, area_id, instantiate=true)
      fail TypeError unless ospf_router.is_a?(String)
      fail TypeError unless vrf_name.is_a?(String)
      fail TypeError unless area_id.is_a?(String)
      fail ArgumentError unless ospf_router.length > 0
      fail ArgumentError unless vrf_name.length > 0
      fail ArgumentError unless area_id.length > 0

      # check the area_id is a proper ipv4 address
      fail ArgumentError if (begin
                               IPAddr.new(area_id)
                             rescue
                               nil
                             end).nil?
      fail ArgumentError unless IPAddr.new(area_id).ipv4?

      @router = ospf_router
      @vrf = vrf_name
      @area_id = area_id

      set_args_keys_default
      create if instantiate
    end

    def self.areas
      hash_final = {}
      RouterOspf.routers.each do |instance|
        name = instance[0]
        area_ids = config_get('ospf_area', 'areas', name: name)
        unless area_ids.nil?
          area_ids.uniq.each do |area|
            hash_final[name]['default'][area] =
              RouterOspfArea.new(name, vrf, area, false)
          end
        end
        vrf_ids = config_get('ospf', 'vrf', name: name)
        next if vrf_ids.nil?
        vrf_ids.each do |vrf|
          area_ids = config_get('ospf_area', 'areas', name: name, vrf: vrf)
          next if area_ids.nil?
          area_ids.uniq.each do |area|
            hash_final[name][vrf][area] =
              RouterOspfArea.new(name, vrf, area, false)
          end
        end
      end
      hash_final
    end

    # Helper method to delete @set_args hash keys
    def set_args_keys_default
      @set_args = { name: @router }
      @set_args[:vrf] = @vrf unless @vrf == 'default'
      @set_args[:area] = @area_id
      @get_args = @set_args
    end

    # rubocop:disable Style/AccessorMethodName
    def set_args_keys(hash={})
      set_args_keys_default
      @set_args = @get_args.merge!(hash) unless hash.empty?
    end

    def create
      # create RouterOspfVrf only
      # area_id is used at each config cli, not as a context
      RouterOspfVrf.new(@router, @vrf)
    end

    def destroy
      return unless Feature.ospf_enabled?
      [:authentication,
       :default_cost,
       :filter_list_in,
       :filter_list_out,
       :range,
       :stub,
      ].each do |prop|
        send("#{prop}=", send("default_#{prop}"))
      end
      set_args_keys_default
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    def authentication
      auth = config_get('ospf_area', 'authentication', @get_args)
      return auth unless auth
      auth.include?('message-digest') ? 'md5' : 'clear_text'
    end

    def authentication=(val)
      state = val ? '' : 'no'
      auth = (val == 'md5') ? 'message-digest' : ''
      set_args_keys(state: state, auth: auth)
      config_set('ospf_area', 'authentication', @set_args)
    end

    def default_authentication
      config_get_default('ospf_area', 'authentication')
    end

    def default_cost
      config_get('ospf_area', 'default_cost', @get_args)
    end

    def default_cost=(val)
      state = val ? '' : 'no'
      cost = val ? val : ''
      set_args_keys(state: state, cost: cost)
      config_set('ospf_area', 'default_cost', @set_args)
    end

    def default_default_cost
      config_get_default('ospf_area', 'default_cost')
    end

    def filter_list_in
      config_get('ospf_area', 'filter_list_in', @get_args)
    end

    def filter_list_in=(val)
      return if filter_list_in == false && val == false
      state = val ? '' : 'no'
      rm = val ? val : filter_list_in
      set_args_keys(state: state, route_map: rm)
      config_set('ospf_area', 'filter_list_in', @set_args)
    end

    def default_filter_list_in
      config_get_default('ospf_area', 'filter_list_in')
    end

    def filter_list_out
      config_get('ospf_area', 'filter_list_out', @get_args)
    end

    def filter_list_out=(val)
      return if filter_list_out == false && val == false
      state = val ? '' : 'no'
      rm = val ? val : filter_list_out
      set_args_keys(state: state, route_map: rm)
      config_set('ospf_area', 'filter_list_out', @set_args)
    end

    def default_filter_list_out
      config_get_default('ospf_area', 'filter_list_out')
    end

    def stub
      stu = config_get('ospf_area', 'stub', @get_args)
      return stu unless stu
      stu.include?('no-summary') ? 'no_summary' : 'summary'
    end

    def stub=(val)
      # we need to reset stub property first
      state = 'no'
      stu = ''
      set_args_keys(state: state, stub: stu)
      config_set('ospf_area', 'stub', @set_args)
      return unless val # go further only if the val is not false
      state = ''
      stu = (val == 'no_summary') ? 'no-summary' : ''
      set_args_keys(state: state, stub: stu)
      config_set('ospf_area', 'stub', @set_args)
    end

    def default_stub
      config_get_default('ospf_area', 'stub')
    end
  end # class
end # module
