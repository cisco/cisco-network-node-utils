# -*- coding: utf-8 -*-
#
# NXAPI implementation of RouterBgp Address Family class
#
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

require File.join(File.dirname(__FILE__), 'node')
require File.join(File.dirname(__FILE__), 'bgp')

module Cisco
  class RouterBgpAF
    @@node = Node.instance

    def initialize(asn, vrf, af, instantiate=true)
      raise ArgumentError if
        vrf.to_s.empty? or af.to_s.empty?
      err_msg = "‘af’ argument must be an array of two string values containing " +
                "an afi + safi tuple"
      raise ArgumentError, err_msg  unless af.is_a? Array or af.length == 2
      @asn = RouterBgp.process_asnum(asn)
      @vrf = vrf
      @afi, @safi = af
      set_args_keys_default
      create if instantiate
    end

    def RouterBgpAF.afs
      af_hash = {}
      RouterBgp.routers.each { |asn, vrfs|
        af_hash[asn] = {}
        vrfs.keys.each { |vrf_name|
          get_args = { :asnum => asn }
          get_args[:vrf] = vrf_name unless (vrf_name == 'default')
          # Call yaml and search for address-family statements
          af_list = @@node.config_get("bgp_af", "all_afs", get_args)

          next if af_list.nil?

          af_hash[asn][vrf_name] = {}
          af_list.each { |af|
            af_hash[asn][vrf_name][af] = RouterBgpAF.new(asn, vrf_name, af, false)
          }
        }
      }
      af_hash
    end

    def create
      set_args_keys({ :state => "" })
      @@node.config_set("bgp", "address_family", @set_args)
    end

    def destroy
      set_args_keys({ :state => "no" })
      @@node.config_set("bgp", "address_family", @set_args)
    end

    #
    # Helper methods to delete @set_args hash keys
    #
    def set_args_keys_default
      keys = { :asnum => @asn, :afi => @afi, :safi => @safi }
      keys[:vrf] = @vrf unless @vrf == 'default'
      @get_args = @set_args = keys
    end

    def set_args_keys(hash = {})
      set_args_keys_default
      @set_args = @get_args.merge!(hash) unless hash.empty?
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    #
    # Client to client
    #
    def client_to_client
      state = @@node.config_get("bgp_af", "client_to_client", @get_args)
      state ? true : false
    end

    def client_to_client=(state)
      state = (state ? '' : 'no')
      set_args_keys({ :state => state })
      @@node.config_set('bgp_af', 'client_to_client', @set_args)
    end

    def default_client_to_client
      @@node.config_get_default("bgp_af", "client_to_client")
    end

    #
    # Default Information (Getter/Setter/Default)
    #
    def default_information_originate
      state = @@node.config_get("bgp_af", "default_information", @get_args)
      state ? true : false
    end

    def default_information_originate=(state)
      state = (state ? '' : 'no')
      set_args_keys({ :state => state })
      @@node.config_set('bgp_af', 'default_information', @set_args)
    end

    def default_default_information_originate
      @@node.config_get_default("bgp_af", "default_information")
    end

    #
    # Next Hop route map (Getter/Setter/Default)
    #
    def nexthop_route_map
      route_map = @@node.config_get("bgp_af", "nexthop_route_map", @get_args)
      return "" if route_map.nil?
      route_map.shift.strip
    end

    def nexthop_route_map=(route_map)
      route_map.strip!
      state, route_map = "no", nexthop_route_map if route_map.empty?
      set_args_keys(:state => state, :route_map => route_map)
      @@node.config_set("bgp_af", "nexthop_route_map", @set_args)
    end

    def default_nexthop_route_map
      @@node.config_get_default("bgp_af", "nexthop_route_map")
    end
  end
end
