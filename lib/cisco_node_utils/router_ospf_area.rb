# Rohan Gandhi Korlepara, May 2016
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
require_relative 'router_ospf'
require_relative 'router_ospf_vrf'

module Cisco
  # RouterOspfVrf - node utility class for per-VRF OSPF config management
  class RouterOspfArea < NodeUtil
    attr_reader :name, :parent

    def initialize(router, vrf_name, area_id, instantiate=true)
      fail TypeError if router.nil?
      fail TypeError if vrf_name.nil?
      fail TypeError if area_id.nil?
      fail ArgumentError unless router.length > 0
      fail ArgumentError unless vrf_name.length > 0
      fail ArgumentError unless area_id.length > 0
      @router = router
      @vrf_name = vrf_name
      @area_id = area_id
      @parent = {}
      if @name == 'default'
        @get_args = @set_args = { name: @router, area: @area_id }
      else
        @get_args = @set_args = { name: @router, vrf: @vrf_name,
            area: @area_id }
      end

      create if instantiate
    end

    def self.areas
      hash_final = {}
      hash_tmp = {}
      RouterOspf.routers.each do |instance|
        name = instance[0]
        area_ids = config_get('ospf', 'area', name: name)
        unless area_ids.nil?
          area_ids.uniq.each do |area|
            hash_tmp =
              { name => { 'default' => { area => RouterOspfArea
                                                 .new(name, 'default',
                                                      area, false) } } }
          end
        end
        vrf_ids = config_get('ospf', 'vrf', name: name)
        unless vrf_ids.nil?
          vrf_ids.each do |vrf|
            area_ids = config_get('ospf', 'area', name: name, vrf: vrf)
            next if area_ids.nil?
            area_ids.uniq.each do |area|
              hash_tmp =
                { name => { vrf => { area => RouterOspfArea
                                             .new(name, 'default',
                                                  area, false) } } }
            end
          end
        end
        hash_final.merge!(hash_tmp)
      end
      hash_final
    end

    # Create one router ospf vrf instance
    def create
      @parent = RouterOspfVrf.new(@router, @vrf_name)
    end

    # Destroy one router ospf vrf instance
    def destroy
      self.authentication = ''
      self.cost = ''
      self.filter_list_in = ''
      self.filter_list_out = ''
    end

    # Helper method to delete @set_args hash keys
    def delete_set_args_keys(list)
      list.each { |key| @set_args.delete(key) }
    end

    def authentication
      auth = config_get('ospf', 'area_authentication', @get_args)
      return auth if auth.nil?
      (auth.eql? 'message-digest') ? 'md5' : 'simple'
    end

    def authentication=(val)
      @set_args[:auth_type] = (val.eql? 'simple') ? '' : 'message-digest'
      @set_args[:state] = (val.empty?) ? 'no' : ''
      config_set('ospf', 'area_authentication', @set_args)
      delete_set_args_keys([:auth_type, :state])
    end

    def default_authentication
      config_get_default('ospf', 'area_authentication')
    end

    def cost
      config_get('ospf', 'area_default_cost', @get_args)
    end

    def cost=(val)
      @set_args[:state] = (val.to_s.empty?) ? 'no' : ''
      @set_args[:cost] = (@set_args[:state] == 'no') ? '' : val.to_i
      config_set('ospf', 'area_default_cost', @set_args)
      delete_set_args_keys([:cost, :state])
    end

    def default_cost
      config_get_default('ospf', 'area_default_cost')
    end

    def filter_list_in
      config_get('ospf', 'filter_list_in', @get_args)
    end

    def filter_list_in=(val)
      @set_args[:state] = (val.to_s.empty?) ? 'no' : ''
      if @set_args[:state] == 'no'
        @set_args[:route_map] = (filter_list_in.nil?) ? '' : filter_list_in
      else
        @set_args[:route_map] = val
      end
      config_set('ospf', 'filter_list_in', @set_args)
      delete_set_args_keys([:route_map, :state])
    end

    def default_filter_list_in
      config_get_default('ospf', 'filter_list_in')
    end

    def filter_list_out
      config_get('ospf', 'filter_list_out', @get_args)
    end

    def filter_list_out=(val)
      @set_args[:state] = (val.to_s.empty?) ? 'no' : ''
      if @set_args[:state] == 'no'
        @set_args[:route_map] = (filter_list_out.nil?) ? '' : filter_list_out
      else
        @set_args[:route_map] = val
      end
      config_set('ospf', 'filter_list_out', @set_args)
      delete_set_args_keys([:route_map, :state])
    end

    def default_filter_list_out
      config_get_default('ospf', 'filter_list_out')
    end
  end
end
