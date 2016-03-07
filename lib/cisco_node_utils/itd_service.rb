# Mar 2016, Sai Chintalapudi
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
  # node_utils class for itd_device_group
  class ItdService < NodeUtil
    attr_reader :name

    def initialize(name, instantiate=true)
      fail TypeError unless name.is_a?(String)
      fail ArgumentError unless name.length > 0
      @name = name

      set_args_keys_default
      create if instantiate
    end

    def self.itds
      hash = {}
      list = []
      services = config_get('itd_service',
                            'all_itds')
      return hash if services.nil?

      services.each do |service|
        # The show cmd shows more than name sometimes,
        # and also we get other things like device-groups etc.
        # so filter it out to just get the name
        next if service.include?('device-group')
        next if service.include?('session')
        next if service.include?('statistics')
        list << service
      end

      list.each do |id|
        hash[id] = ItdService.new(id, false)
      end
      hash
    end

    # feature itd
    def self.feature_itd_enabled
      config_get('itd_service', 'feature')
    rescue Cisco::CliError => e
      # cmd will syntax reject when feature is not enabled
      raise unless e.clierror =~ /Syntax error/
      return false
    end

    def self.feature_itd_enable
      config_set('itd_service', 'feature')
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    def create
      ItdService.feature_itd_enable unless
        ItdService.feature_itd_enabled
      config_set('itd_service', 'create', name: @name)
    end

    def destroy
      config_set('itd_service', 'destroy', name: @name)
    end

    # Helper method to delete @set_args hash keys
    def set_args_keys_default
      @set_args = { name: @name }
      @get_args = @set_args
    end

    def access_list
      config_get('itd_service', 'access_list', @get_args)
    end

    def access_list=(val)
      if val
        @set_args[:state] = ''
        @set_args[:al] = val
      else
        @set_args[:state] = 'no'
        @set_args[:al] = access_list
      end
      config_set('itd_service',
                 'access_list', @set_args)
      set_args_keys_default
    end

    def default_access_list
      config_get_default('itd_service', 'access_list')
    end

    def device_group
      config_get('itd_service', 'device_group', @get_args)
    end

    def device_group=(val)
      if val
        @set_args[:state] = ''
        @set_args[:dg] = val
      else
        @set_args[:state] = 'no'
        @set_args[:dg] = device_group
      end
      config_set('itd_service',
                 'device_group', @set_args)
      set_args_keys_default
    end

    def default_device_group
      config_get_default('itd_service', 'device_group')
    end

    def exclude_access_list
      config_get('itd_service', 'exclude_access_list', @get_args)
    end

    def exclude_access_list=(val)
      if val
        @set_args[:state] = ''
        @set_args[:al] = val
      else
        @set_args[:state] = 'no'
        @set_args[:al] = exclude_access_list
      end
      config_set('itd_service',
                 'exclude_access_list', @set_args)
      set_args_keys_default
    end

    def default_exclude_access_list
      config_get_default('itd_service', 'exclude_access_list')
    end

    def failaction
      config_get('itd_service', 'failaction', @get_args)
    end

    def failaction=(state)
      no_cmd = (state ? '' : 'no')
      @set_args[:state] = no_cmd
      config_set('itd_service', 'failaction', @set_args)
      set_args_keys_default
    end

    def default_failaction
      config_get_default('itd_service', 'failaction')
    end

    # the load-balance command can take several forms like:
    # load-balance method dst ip
    # load-balance method dst ip-l4port tcp range 3 6
    # load-balance method dst ip-l4port tcp range 3 6 buckets 8 mask-position 2
    # load-balance buckets 8
    # load-balance mask-position 2
    def load_balance
      hash = {}
      hash[:state] = false
      hash[:buckets] = false
      hash[:mask] = false
      hash[:bundle_select] = false
      hash[:bundle_hash] = false
      hash[:proto] = false
      hash[:start_port] = false
      hash[:end_port] = false
      lb = config_get('itd_service', 'load_balance', @get_args)
      return hash if lb.nil?
      hash[:state] = true
      params = lb.split
      bi = params.index('buckets')
      hash[:buckets] = params[bi + 1].to_i unless bi.nil?
      mi = params.index('mask-position')
      hash[:mask] = params[mi + 1].to_i unless mi.nil?
      mei = params.index('method')
      unless mei.nil?
        hash[:bundle_select] = params[mei + 1]
        hash[:bundle_hash] = params[mei + 2]
      end
      ri = params.index('range')
      unless ri.nil?
        hash[:proto] = params[ri - 1]
        hash[:start_port] = params[ri + 1].to_i
        hash[:end_port] = params[ri + 2].to_i
      end
      hash
    end

    def load_bal_buckets
      load_balance[:buckets]
    end

    def default_load_bal_buckets
      config_get_default('itd_service', 'load_bal_buckets')
    end

    def load_bal_mask_pos
      load_balance[:mask]
    end

    def default_load_bal_mask_pos
      config_get_default('itd_service', 'load_bal_mask_pos')
    end

    def load_bal_method_bundle_hash
      load_balance[:bundle_hash]
    end

    def default_load_bal_method_bundle_hash
      config_get_default('itd_service', 'load_bal_method_bundle_hash')
    end

    def load_bal_method_bundle_select
      load_balance[:bundle_select]
    end

    def default_load_bal_method_bundle_select
      config_get_default('itd_service', 'load_bal_method_bundle_select')
    end

    def load_bal_method_end_port
      load_balance[:end_port]
    end

    def default_load_bal_method_end_port
      config_get_default('itd_service', 'load_bal_method_end_port')
    end

    def load_bal_method_start_port
      load_balance[:start_port]
    end

    def default_load_bal_method_start_port
      config_get_default('itd_service', 'load_bal_method_start_port')
    end

    def load_bal_method_proto
      load_balance[:proto]
    end

    def default_load_bal_method_proto
      config_get_default('itd_service', 'load_bal_method_proto')
    end

    def load_bal_enable
      load_balance[:state]
    end

    def default_load_bal_enable
      config_get_default('itd_service', 'load_bal_enable')
    end

    def load_balance=(enable, bs, bh, buck, mask, proto, stport, enport)
      no_cmd = (enable ? '' : 'no')
      @set_args[:state] = no_cmd
      if bs == false
        @set_args[:method] = ''
        @set_args[:bs] = ''
        @set_args[:bh] = ''
      else
        @set_args[:method] = 'method'
        @set_args[:bs] = bs
        @set_args[:bh] = bh
      end
      if proto == false
        @set_args[:range] = ''
        @set_args[:proto] = ''
        @set_args[:start] = ''
        @set_args[:end] = ''
      else
        @set_args[:range] = 'range'
        @set_args[:proto] = proto
        @set_args[:start] = stport
        @set_args[:end] = enport
      end
      if buck == false
        @set_args[:buck] = ''
        @set_args[:buckets] = ''
      else
        @set_args[:buck] = 'buckets'
        @set_args[:buckets] = buck
      end
      if mask == false
        @set_args[:mpos] = ''
        @set_args[:mask] = ''
      else
        @set_args[:mpos] = 'mask-position'
        @set_args[:mask] = mask
      end
      config_set('itd_service', 'load_balance', @set_args)
    end

    # peer is an array of vdc and service
    def peer
      config_get('itd_service', 'peer', @get_args)
    end

    # peer is an array of vdc and service
    # ex: ['switch', 'myservice']
    def peer=(parray)
      if parray.empty?
        @set_args[:state] = 'no'
        current_peer = peer
        @set_args[:vdc] = current_peer[0]
        @set_args[:service] = current_peer[1]
      else
        @set_args[:state] = ''
        @set_args[:vdc] = parray[0]
        @set_args[:service] = parray[1]
      end
      config_set('itd_service', 'peer', @set_args)
    end

    def default_peer
      config_get_default('itd_service', 'peer')
    end

    def shutdown
      config_get('itd_service', 'shutdown', @get_args)
    end

    def shutdown=(state)
      no_cmd = (state ? '' : 'no')
      @set_args[:state] = no_cmd
      config_set('itd_service', 'shutdown', @set_args)
    end

    def default_shutdown
      config_get_default('itd_service', 'shutdown')
    end

    def vrf
      config_get('itd_service', 'vrf', @get_args)
    end

    def vrf=(val)
      if val
        @set_args[:state] = ''
        @set_args[:vrf] = val
      else
        @set_args[:state] = 'no'
        @set_args[:vrf] = vrf
      end
      config_set('itd_service',
                 'vrf', @set_args)
      set_args_keys_default
    end

    def default_vrf
      config_get_default('itd_service', 'vrf')
    end
  end  # Class
end    # Module
