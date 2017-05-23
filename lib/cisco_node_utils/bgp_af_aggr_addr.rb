# May 2017, Sai Chintalapudi
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
require_relative 'bgp'
require_relative 'bgp_af'

module Cisco
  # node_utils class for bgp address-family aggregate address management
  class RouterBgpAFAggrAddr < NodeUtil
    attr_reader :asn, :vrf, :afi, :safi, :aa

    def initialize(asn, vrf, af, aggr_addr, instantiate=true)
      @asn = asn
      @asn = asn.to_i unless /\d+.\d+/.match(asn.to_s)
      @vrf = vrf
      @afi, @safi = af
      @aa = aggr_addr
      temp_af = [@afi.to_s, @safi.to_s]
      @bgp_af = RouterBgpAF.afs[@asn][vrf][temp_af]
      fail "bgp address family #{@asn} #{vrf} #{af} does not exist" if
        @bgp_af.nil?
      set_args_keys_default
      create if instantiate
    end

    def self.aas
      aa_hash = {}
      RouterBgpAF.afs.each do |asn, vrfs|
        aa_hash[asn] = {}
        vrfs.each do |vrf, afs|
          aa_hash[asn][vrf] = {}
          afs.each do |af, _obj|
            aa_hash[asn][vrf][af] = {}
            afi, safi = af
            get_args = { asnum: asn, afi: afi, safi: safi }
            get_args[:vrf] = vrf unless vrf == 'default'
            aa_list = config_get('bgp_af_aa', 'all_aa', get_args)
            next if aa_list.nil?
            aa_list.each do |aa|
              aa_hash[asn][vrf][af][aa] =
                RouterBgpAFAggrAddr.new(asn, vrf, af, aa, false)
            end
          end
        end
      end
      aa_hash
    end

    # Helper method to delete @set_args hash keys
    def set_args_keys_default
      keys = { asnum: @asn, afi: @afi, safi: @safi, address: @aa }
      keys[:vrf] = @vrf unless @vrf == 'default'
      @get_args = @set_args = keys
    end

    # rubocop:disable Style/AccessorMethodName
    def set_args_keys(hash={})
      set_args_keys_default
      @set_args = @get_args.merge!(hash) unless hash.empty?
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    def create
      set_args_keys(state: '', as_set: '', summ: '', advertise: '',
                    admap: '', suppress: '', sumap: '', attribute: '',
                    atmap: '')
      config_set('bgp_af_aa', 'aggr_addr', @set_args)
    end

    def destroy
      set_args_keys(state: 'no', as_set: '', summ: '', advertise: '',
                    admap: '', suppress: '', sumap: '', attribute: '',
                    atmap: '')
      config_set('bgp_af_aa', 'aggr_addr', @set_args)
    end

    def aa_maps_get
      str = config_get('bgp_af_aa', 'aggr_addr', @get_args)
      return if str.nil?
      str.slice!('as-set') if str.include?('as-set')
      str.slice!('summary-only') if str.include?('summary-only')
      str.strip!
      return if str.empty?
      regexp = Regexp.new(' *(?<admap>advertise-map \S+)?'\
                          ' *(?<sumap>suppress-map \S+)?'\
                          ' *(?<atmap>attribute-map \S+)?')
      regexp.match(str)
    end

    def as_set
      str = config_get('bgp_af_aa', 'aggr_addr', @get_args)
      return false if str.nil?
      str.include?('as-set') ? true : false
    end

    def as_set=(val)
      @set_args[:as_set] = val ? 'as-set' : ''
    end

    def default_as_set
      config_get_default('bgp_af_aa', 'as_set')
    end

    def summary_only
      str = config_get('bgp_af_aa', 'aggr_addr', @get_args)
      return false if str.nil?
      str.include?('summary-only') ? true : false
    end

    def summary_only=(val)
      @set_args[:summ] = val ? 'summary-only' : ''
    end

    def default_summary_only
      config_get_default('bgp_af_aa', 'summary_only')
    end

    def advertise_map
      val = Utils.extract_value(aa_maps_get, 'admap', 'advertise-map')
      return default_advertise_map if val.nil?
      val
    end

    def advertise_map=(map)
      @set_args[:advertise] =
          Utils.attach_prefix(map, :advertise, 'advertise-map')
    end

    def default_advertise_map
      config_get_default('bgp_af_aa', 'advertise_map')
    end

    def suppress_map
      val = Utils.extract_value(aa_maps_get, 'sumap', 'suppress-map')
      return default_suppress_map if val.nil?
      val
    end

    def suppress_map=(map)
      @set_args[:suppress] =
          Utils.attach_prefix(map, :suppress, 'suppress-map')
    end

    def default_suppress_map
      config_get_default('bgp_af_aa', 'suppress_map')
    end

    def attribute_map
      val = Utils.extract_value(aa_maps_get, 'atmap', 'attribute-map')
      return default_attribute_map if val.nil?
      val
    end

    def attribute_map=(map)
      @set_args[:attribute] =
          Utils.attach_prefix(map, :attribute, 'attribute-map')
    end

    def default_attribute_map
      config_get_default('bgp_af_aa', 'attribute_map')
    end

    # The CLI can take many forms like:
    # aggregate-address 1.1.1.1/32 as-set advertise-map adm
    # aggregate-address 1.1.1.1/32 suppress-map sum attribute-map atm
    # aggregate-address 1.1.1.1/32 summary-only
    # aggregate-address 2.2.2.2/32 summary-only
    def aa_set(attrs)
      # reset everything before setting as some older
      # software versions require it.
      destroy
      set_args_keys_default
      [:suppress_map,
       :advertise_map,
       :attribute_map,
      ].each do |p|
        attrs[p] = '' if attrs[p].nil? || attrs[p] == false
        send(p.to_s + '=', attrs[p])
      end
      [:summary_only,
       :as_set,
      ].each do |p|
        attrs[p] = false if attrs[p].nil?
        send(p.to_s + '=', attrs[p])
      end
      @set_args[:state] = ''
      config_set('bgp_af_aa', 'aggr_addr', @set_args)
    end
  end # Class
end # Module
