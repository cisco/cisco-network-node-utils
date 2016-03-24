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
      # the service MUST be shutdown before it can be destroyed
      config_set('itd_service', 'shutdown', name: @name, state: '')
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
      if val.empty?
        @set_args[:state] = 'no'
        @set_args[:al] = access_list
        config_set('itd_service', 'access_list', @set_args) unless
        access_list.empty?
      else
        @set_args[:state] = ''
        @set_args[:al] = val
        config_set('itd_service', 'access_list', @set_args)
      end
      set_args_keys_default
    end

    def default_access_list
      config_get_default('itd_service', 'access_list')
    end

    def device_group
      config_get('itd_service', 'device_group', @get_args)
    end

    def device_group=(val)
      if val.empty?
        @set_args[:state] = 'no'
        @set_args[:dg] = device_group
        config_set('itd_service', 'device_group', @set_args) unless
        device_group.empty?
      else
        @set_args[:state] = ''
        @set_args[:dg] = val
        config_set('itd_service', 'device_group', @set_args)
      end
      set_args_keys_default
    end

    def default_device_group
      config_get_default('itd_service', 'device_group')
    end

    def exclude_access_list
      config_get('itd_service', 'exclude_access_list', @get_args)
    end

    def exclude_access_list=(val)
      if val.empty?
        @set_args[:state] = 'no'
        @set_args[:al] = exclude_access_list
        config_set('itd_service', 'exclude_access_list', @set_args) unless
        exclude_access_list.empty?
      else
        @set_args[:state] = ''
        @set_args[:al] = val
        config_set('itd_service', 'exclude_access_list', @set_args)
      end
      set_args_keys_default
    end

    def default_exclude_access_list
      config_get_default('itd_service', 'exclude_access_list')
    end

    def fail_action
      config_get('itd_service', 'fail_action', @get_args)
    end

    def fail_action=(state)
      no_cmd = (state ? '' : 'no')
      @set_args[:state] = no_cmd
      config_set('itd_service', 'fail_action', @set_args)
      set_args_keys_default
    end

    def default_fail_action
      config_get_default('itd_service', 'fail_action')
    end

    # this is an array like:
    # [['ethernet 1/1', '1.1.1.1'], ['port-channel 100', '2.2.2.2'],
    # ['vlan 2', '3.3.3.3']]
    # show command output is like: Eth1/1, Po100, Vlan2
    # so translate back to the input format
    def ingress_interface
      list = config_get('itd_service', 'ingress_interface', @get_args)
      list.each do |intf, _next_hop|
        intf.gsub!('Eth', 'ethernet ')
        intf.gsub!('Po', 'port-channel ')
        intf.gsub!('Vlan', 'vlan ')
      end
      list
    end

    def ingress_interface_cleanup
      cur_list = ingress_interface
      return if cur_list.empty?
      @set_args[:state] = 'no'
      @set_args[:next] = ''
      @set_args[:nhop] = ''
      # clean up the current list first
      cur_list.each do |intf, _next_hop|
        @set_args[:interface] = intf
        config_set('itd_service', 'ingress_interface', @set_args)
      end
    end

    # only one next-hop is allowed per interface but
    # due to nxos issues, it allows more than one;
    # so the workaround is to clean up the current ingress
    # intf and configure all of them again
    def ingress_interface=(list)
      ingress_interface_cleanup
      @set_args[:state] = ''
      list.each do |intf, next_hop|
        @set_args[:interface] = intf
        @set_args[:next] = ''
        @set_args[:nhop] = ''
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

    def load_bal_buckets=(buckets)
      attach_prefix(buckets, :buckets)
    end

    def default_load_bal_buckets
      config_get_default('itd_service', 'load_bal_buckets')
    end

    def load_bal_mask_pos
      val = extract_value('mask', 'mask-position')
      return default_load_bal_mask_pos if val.nil?
      val.to_i
    end

    def load_bal_mask_pos=(mask)
      attach_prefix(mask, :mask, 'mask-position')
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

    def load_bal_method_bundle_hash=(bh)
      @set_args[:bundle_hash] = bh
    end

    def default_load_bal_method_bundle_hash
      config_get_default('itd_service', 'load_bal_method_bundle_hash')
    end

    def load_bal_method_bundle_select
      val = extract_value('bundle_select', 'method')
      return default_load_bal_method_bundle_select if val.nil?
      val
    end

    def load_bal_method_bundle_select=(bs)
      attach_prefix(bs, :bundle_select, 'method')
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

    def load_bal_method_end_port=(enport)
      @set_args[:endPort] = enport
    end

    def default_load_bal_method_end_port
      config_get_default('itd_service', 'load_bal_method_end_port')
    end

    def load_bal_method_start_port
      val = extract_value('start_port', 'range')
      return default_load_bal_method_start_port if val.nil?
      val.to_i
    end

    def load_bal_method_start_port=(start)
      attach_prefix(start, :start_port, 'range')
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

    def load_bal_method_proto=(proto)
      @set_args[:proto] = proto
    end

    def default_load_bal_method_proto
      config_get_default('itd_service', 'load_bal_method_proto')
    end

    def load_bal_enable
      lb_get.nil? ? default_load_bal_enable : true
    end

    def load_bal_enable=(enable)
      @set_args[:state] = enable ? '' : 'no'
    end

    def default_load_bal_enable
      config_get_default('itd_service', 'load_bal_enable')
    end

    def load_balance_set(attrs)
      set_args_keys_default
      set_args_keys(attrs)
      [:load_bal_buckets,
       :load_bal_mask_pos,
       :load_bal_method_bundle_hash,
       :load_bal_method_bundle_select,
       :load_bal_method_end_port,
       :load_bal_method_start_port,
       :load_bal_method_proto,
       :load_bal_enable,
      ].each do |p|
        attrs[p] = '' if attrs[p].nil? || attrs[p] == false
        send(p.to_s + '=', attrs[p])
      end
      # for boolean we need to do this
      send('load_bal_enable=', false) if attrs[:load_bal_enable] == ''
      @get_args = @set_args
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

    def peer_local=(val)
      if val.empty?
        @set_args[:state] = 'no'
        current_peer_local = peer_local
        @set_args[:service] = current_peer_local
        config_set('itd_service', 'peer_local', @set_args) unless
        current_peer_local.nil? || current_peer_local.empty?
      else
        @set_args[:state] = ''
        @set_args[:service] = val
        config_set('itd_service', 'peer_local', @set_args)
      end
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
    # only one peer_vdc is allowed per service
    # ex: ['switch', 'myservice']
    def peer_vdc=(parray)
      if parray.empty?
        @set_args[:state] = 'no'
        current_peer_vdc = peer_vdc
        @set_args[:vdc] = current_peer_vdc[0]
        @set_args[:service] = current_peer_vdc[1]
        config_set('itd_service', 'peer_vdc', @set_args) unless
        current_peer_vdc[0].nil? || current_peer_vdc[1].nil?
      else
        @set_args[:state] = ''
        @set_args[:vdc] = parray[0]
        @set_args[:service] = parray[1]
        config_set('itd_service', 'peer_vdc', @set_args)
      end
      set_args_keys_default
    end

    def default_peer_vdc
      config_get_default('itd_service', 'peer_vdc')
    end

    # show command shows nothing when the service is
    # shutdown which is default, but it shows "no shut"
    # when it is not shut
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

    # VIP is a large string like:
    # virtual ip 2.2.2.2 10.0.0.0 udp 10 advertise enable device-group icmpGroup
    # virtual ip 2.2.2.2 10.0.0.0 udp 10 advertise enable
    # virtual ip 2.2.2.2 10.0.0.0 udp 10
    # virtual ip 2.2.2.2 10.0.0.0
    # all of the above are unique and can be added one after the other
    # the entire string is unique but not individual parts of it
    # currently, only one VIP can be configured due to nxos issue
    # else, the switch crashes, this limitation will be set in
    # puppet manifest. Also remove the current VIPs before configuring more
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
  end  # Class
end    # Module
