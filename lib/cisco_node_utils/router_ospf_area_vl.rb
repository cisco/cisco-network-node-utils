#
# NXAPI implementation of Router OSPF Area Virtual-link class
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

require_relative 'node_util'

module Cisco
  # node_utils class for ospf_area
  class RouterOspfAreaVirtualLink < NodeUtil
    attr_reader :router, :vrf, :area_id, :vl

    def initialize(ospf_router, vrf_name, area_id, virtual_link,
                   instantiate=true)
      fail TypeError unless ospf_router.is_a?(String)
      fail TypeError unless vrf_name.is_a?(String)
      fail ArgumentError unless ospf_router.length > 0
      fail ArgumentError unless vrf_name.length > 0
      @area_id = area_id.to_s
      fail ArgumentError if @area_id.empty?
      fail ArgumentError unless virtual_link.length > 0

      Feature.ospf_enable if instantiate
      # Convert to dot-notation

      @router = ospf_router
      @vrf = vrf_name
      @area_id = IPAddr.new(area_id.to_i, Socket::AF_INET) unless @area_id[/\./]
      @vl = virtual_link

      set_args_keys_default
    end

    def self.virtual_links
      hash = {}
      RouterOspf.routers.each do |name, _obj|
        # get all virtual_links under default vrf
        links = config_get('ospf_area', 'virtual_links', name: name)
        unless links.empty?
          hash[name] = {}
          hash[name]['default'] = {}
          links.each do |area, vl|
            hash[name]['default'][vl] =
              RouterOspfAreaVirtualLink.new(name, 'default', area, vl, false)
          end
        end
        vrf_ids = config_get('ospf', 'vrf', name: name)
        next if vrf_ids.nil?
        vrf_ids.each do |vrf|
          # get all virtual_links under each vrf
          links = config_get('ospf_area', 'virtual_links', name: name, vrf: vrf)
          next if links.empty?
          hash[name] ||= {}
          hash[name][vrf] = {}
          links.each do |area, vl|
            hash[name][vrf][vl] =
              RouterOspfAreaVirtualLink.new(name, vrf, area, vl, false)
          end
        end
      end
      hash
    end

    # Helper method to delete @set_args hash keys
    def set_args_keys_default
      @set_args = { name: @router, area: @area_id, vl: @vl }
      @set_args[:vrf] = @vrf unless @vrf == 'default'
      @get_args = @set_args
    end

    # rubocop:disable Style/AccessorMethodName
    def set_args_keys(hash={})
      set_args_keys_default
      @set_args = @get_args.merge!(hash) unless hash.empty?
    end

    def destroy
      return unless Feature.ospf_enabled?
      config_set('ospf_area_vl', 'destroy', @set_args)
      set_args_keys_default
    end

    def ==(other)
      (ospf_router == other.ospf_router) &&
        (vrf_name == other.vrf_name) && (area_id == other.area_id) &&
        (vl == other.vl)
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    def dead_interval
      config_get('ospf_area_vl', 'dead_interval', @get_args)
    end

    def dead_interval=(val)
      set_args_keys(interval: val)
      config_set('ospf_area_vl', 'dead_interval', @set_args)
    end

    def default_dead_interval
      config_get_default('ospf_area_vl', 'dead_interval')
    end

    def hello_interval
      config_get('ospf_area_vl', 'hello_interval', @get_args)
    end

    def hello_interval=(val)
      set_args_keys(interval: val)
      config_set('ospf_area_vl', 'hello_interval', @set_args)
    end

    def default_hello_interval
      config_get_default('ospf_area_vl', 'hello_interval')
    end

    def retransmit_interval
      config_get('ospf_area_vl', 'retransmit_interval', @get_args)
    end

    def retransmit_interval=(val)
      set_args_keys(interval: val)
      config_set('ospf_area_vl', 'retransmit_interval', @set_args)
    end

    def default_retransmit_interval
      config_get_default('ospf_area_vl', 'retransmit_interval')
    end

    def transmit_delay
      config_get('ospf_area_vl', 'transmit_delay', @get_args)
    end

    def transmit_delay=(val)
      set_args_keys(delay: val)
      config_set('ospf_area_vl', 'transmit_delay', @set_args)
    end

    def default_transmit_delay
      config_get_default('ospf_area_vl', 'transmit_delay')
    end
  end # class
end # module
