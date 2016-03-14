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
        # The show cmd shows more than service,
        # we get other things like device-groups etc.
        # so filter it out to just get the service
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

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    def create
      Feature.itd_enable
      config_set('itd_service', 'create', name: @name)
    end

    def destroy
      config_set('itd_service', 'destroy', name: @name)
    end

    # Helper method to delete @set_args hash keys
    def set_args_keys_default
      keys = { name: @name }
      @get_args = @set_args = keys
    end

    # rubocop:disable Style/AccessorMethodName
    def set_args_keys(hash={})
      set_args_keys_default
      @set_args = @get_args.merge!(hash) unless hash.empty?
    end

    # extract value of property from load-balance
    def extract_value(prop, prefix=nil)
      prefix = prop if prefix.nil?
      lb_match = lb_get

      # matching lb not found
      return nil if lb_match.nil? # no matching lb found

      # property not defined for matching lb
      return nil unless lb_match.names.include?(prop)

      # extract and return value that follows prefix + <space>
      regexp = Regexp.new("#{Regexp.escape(prefix)} (?<extracted>.*)")
      value_match = regexp.match(lb_match[prop])
      return nil if value_match.nil?
      value_match[:extracted]
    end

    # prepend property name prefix/keyword to value
    def attach_prefix(val, prop, prefix=nil)
      prefix = prop.to_s if prefix.nil?
      @set_args[prop] = val.to_s.empty? ? val : "#{prefix} #{val}"
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

    def ingress_interface
      list = config_get('itd_service', 'ingress_interface', @get_args)
      list.each do |intf, _next_hop|
        intf[/Eth/] = 'ethernet ' if intf.include?('Eth')
        intf[/Po/] = 'port-channel ' if intf.include?('Po')
        intf[/Vlan/] = 'vlan ' if intf.include?('Vlan')
      end
      list
    end

    def ingress_interface=(list)
      cur_list = ingress_interface
      @set_args[:state] = 'no'
      @set_args[:next] = ''
      @set_args[:nhop] = ''
      # clean up the current list first
      cur_list.each do |intf, _next_hop|
        @set_args[:interface] = intf
        config_set('itd_service', 'ingress_interface', @set_args)
      end
      @set_args[:state] = ''
      list.each do |intf, next_hop|
        @set_args[:interface] = intf
        unless next_hop == '' || next_hop == 'default'
          @set_args[:next] = 'next-hop'
          @set_args[:nhop] = next_hop
        end
        config_set('itd_service', 'ingress_interface', @set_args)
      end
      set_args_keys_default
    end

    def default_ingress_interface
      config_get_default('itd_service', 'ingress_interface')
    end

    # the load-balance command can take several forms like:
    # load-balance method dst ip
    # load-balance method dst ip-l4port tcp range 3 6
    # load-balance method dst ip-l4port tcp range 3 6 buckets 8 mask-position 2
    # load-balance buckets 8
    # load-balance mask-position 2
    def lb_get
      str = config_get('itd_service', 'load_balance', @get_args)
      return nil if str.nil?
      if str.include?('method') && str.include?('range')
        regexp = Regexp.new('load-balance *(?<bundle_select>method \S+)?'\
                 ' *(?<bundle_hash>\S+)?'\
                 ' *(?<proto>\S+)?'\
                 ' *(?<start_port>range \d+)?'\
                 ' *(?<end_port>\d+)?'\
                 ' *(?<buckets>buckets \d+)?'\
                 ' *(?<mask>mask-position \d+)?')
      elsif str.include?('method')
        regexp = Regexp.new('load-balance *(?<bundle_select>method \S+)?'\
                 ' *(?<bundle_hash>\S+)?'\
                 ' *(?<buckets>buckets \d+)?'\
                 ' *(?<mask>mask-position \d+)?') unless str.include?('range')
      else
        regexp = Regexp.new('load-balance *(?<buckets>buckets \d+)?'\
                 ' *(?<mask>mask-position \d+)?')
      end
      regexp.match(str)
    end

    def load_bal_buckets
      val = extract_value('buckets')
      return default_load_bal_buckets if val.nil?
      val.to_i
    end

    def default_load_bal_buckets
      config_get_default('itd_service', 'load_bal_buckets')
    end

    def load_bal_mask_pos
      val = extract_value('mask', 'mask-position')
      return default_load_bal_mask_pos if val.nil?
      val.to_i
    end

    def default_load_bal_mask_pos
      config_get_default('itd_service', 'load_bal_mask_pos')
    end

    def load_bal_method_bundle_hash
      val = default_load_bal_method_bundle_hash
      match = lb_get
      return val if match.nil?
      match.names.include?('bundle_hash') ? match[:bundle_hash] : val
    end

    def default_load_bal_method_bundle_hash
      config_get_default('itd_service', 'load_bal_method_bundle_hash')
    end

    def load_bal_method_bundle_select
      val = extract_value('bundle_select', 'method')
      return default_load_bal_method_bundle_select if val.nil?
      val
    end

    def default_load_bal_method_bundle_select
      config_get_default('itd_service', 'load_bal_method_bundle_select')
    end

    def load_bal_method_end_port
      val = default_load_bal_method_end_port
      match = lb_get
      return val if match.nil?
      match.names.include?('end_port') ? match[:end_port].to_i : val
    end

    def default_load_bal_method_end_port
      config_get_default('itd_service', 'load_bal_method_end_port')
    end

    def load_bal_method_start_port
      val = extract_value('start_port', 'range')
      return default_load_bal_method_start_port if val.nil?
      val.to_i
    end

    def default_load_bal_method_start_port
      config_get_default('itd_service', 'load_bal_method_start_port')
    end

    def load_bal_method_proto
      val = default_load_bal_method_proto
      match = lb_get
      return val if match.nil?
      match.names.include?('proto') ? match[:proto] : val
    end

    def default_load_bal_method_proto
      config_get_default('itd_service', 'load_bal_method_proto')
    end

    def load_bal_enable
      lb_get.nil? ? default_load_bal_enable : true
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
      set_args_keys_default
    end

    def nat_destination
      config_get('itd_service', 'nat_destination', @get_args)
    end

    def nat_destination=(state)
      no_cmd = (state ? '' : 'no')
      @set_args[:state] = no_cmd
      config_set('itd_service', 'nat_destination', @set_args)
      set_args_keys_default
    end

    def default_nat_destination
      config_get_default('itd_service', 'nat_destination')
    end

    def peer_local
      config_get('itd_service', 'peer_local', @get_args)
    end

    def peer_local=(value)
      if value
        @set_args[:state] = ''
        @set_args[:service] = value
      else
        @set_args[:state] = 'no'
        current_peer_local = peer_local
        @set_args[:service] = current_peer_local
      end
      config_set('itd_service', 'peer_local', @set_args)
      set_args_keys_default
    end

    def default_peer_local
      config_get_default('itd_service', 'peer_local')
    end

    # peer_vdc is an array of vdc and service
    def peer_vdc
      config_get('itd_service', 'peer_vdc', @get_args)
    end

    # peer_vdc is an array of vdc and service
    # ex: ['switch', 'myservice']
    def peer_vdc=(parray)
      if parray.empty?
        @set_args[:state] = 'no'
        current_peer_vdc = peer_vdc
        @set_args[:vdc] = current_peer_vdc[0]
        @set_args[:service] = current_peer_vdc[1]
      else
        @set_args[:state] = ''
        @set_args[:vdc] = parray[0]
        @set_args[:service] = parray[1]
      end
      config_set('itd_service', 'peer_vdc', @set_args)
      set_args_keys_default
    end

    def default_peer_vdc
      config_get_default('itd_service', 'peer_vdc')
    end

    def shutdown
      config_get('itd_service', 'shutdown', @get_args)
    end

    def shutdown=(state)
      no_cmd = (state ? '' : 'no')
      @set_args[:state] = no_cmd
      config_set('itd_service', 'shutdown', @set_args)
      set_args_keys_default
    end

    def default_shutdown
      config_get_default('itd_service', 'shutdown')
    end

    def virtual_ip
      config_get('itd_service', 'virtual_ip', @get_args)
    end

    def virtual_ip=(values)
      @set_args[:state] = 'no'
      list = virtual_ip
      # remove all the virtual configs first
      list.each do |line|
        @set_args[:string] = line
        config_set('itd_service', 'virtual_ip', @set_args)
      end
      @set_args[:state] = ''
      values.each do |value|
        @set_args[:string] = value
        config_set('itd_service', 'virtual_ip', @set_args)
      end
      set_args_keys_default
    end

    def default_virtual_ip
      config_get_default('itd_service', 'virtual_ip')
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
