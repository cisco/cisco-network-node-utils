#
# NXAPI implementation of VxlanVtepVni class
#
# November 2015 Michael G Wiebe
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

require_relative 'cisco_cmn_utils'
require_relative 'node_util'
require_relative 'vxlan_vtep'

module Cisco
  # VxlanVtepVni - node utility for vxlan vtep vni members.
  class VxlanVtepVni < NodeUtil
    attr_reader :name, :vni, :vrf

    def initialize(name, vni, vrf=false, instantiate=true)
      @name = name
      @vni = vni
      @vrf = vrf

      create if instantiate
      # NOTE: This can be removed after the puppet type/provider are coded
      # but a few design notes so we don't forget!.
      # 1) The title pattern should be cisco_vxlan_vtep_vni { 'name', 'vni' :
      # 2) vrf will be a property but will also be a namevar.
      # 3) The type must check that vrf is always set to either true or false.
    end

    def self.vnis
      hash = {}
      VxlanVtep.vteps.each do |name, _obj|
        hash[name] = {}
        get_args = { name: name }
        vni_list = config_get('vxlan_vtep_vni', 'all_vnis', get_args)
        next if vni_list.nil?
        vni_list.each do |vni, vrf|
          vrf.nil? ? vrf = false : vrf = true
          hash[name][vni] = VxlanVtepVni.new(name, vni, vrf, false)
        end
      end
      hash
    end

    def ==(other)
      (name == other.name) && (vni == other.vni) && (vrf == other.vrf)
    end

    def set_args_keys_default
      keys = { name: @name, vni: @vni }
      @vrf ? keys[:vrf] = 'associate-vrf' : keys[:vrf] = ''
      @get_args = @set_args = keys
    end

    # rubocop:disable Style/AccessorMethodName
    def set_args_keys(hash={})
      set_args_keys_default
      @set_args = @get_args.merge!(hash) unless hash.empty?
    end
    # rubocop:enable Style/AccessorMethodNamefor

    def create_with_associate_vrf?
      !@set_args[:vrf].eql?('')
    end

    def destroy_existing(key)
      getargs = { name: @name, vni: @vni, state: '' }
      # rubocop:disable Style/GuardClause
      if config_get('vxlan_vtep', key, getargs)
        key.eql?('vni_with_vrf') ? vrf = 'associate-vrf' : vrf = ''
        getargs[:vrf] = vrf
        getargs[:state] = 'no'
        config_set('vxlan_vtep', 'vni', getargs)
      end
      # rubocop:enable Style/GuardClause
    end

    def create
      # The configuration for this resource can be either of the following:
      # - member nve 5000
      # - member nve 5000 associate-vrf
      # They are mutually exclusive and one must be removed before the other
      # can be configured.
      set_args_keys(state: '')
      if create_with_associate_vrf?
        destroy_existing('vni_without_vrf')
      else
        destroy_existing('vni_with_vrf')
      end
      config_set('vxlan_vtep', 'vni', @set_args)
    end

    def destroy
      set_args_keys(state: 'no')
      config_set('vxlan_vtep', 'vni', @set_args)
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    def ingress_replication
      config_get('vxlan_vtep_vni', 'ingress_replication', @get_args)
    end

    def remove_add_ingress_replication(protocol)
      if ingress_replication.empty?
        set_args_keys(state: '', protocol: protocol)
        config_set('vxlan_vtep_vni', 'ingress_replication', @set_args)
      else
        # Sadly, the only way to change between protocols is to
        # first remove the exisitng protocol.
        set_args_keys(state: 'no', protocol: ingress_replication)
        config_set('vxlan_vtep_vni', 'ingress_replication', @set_args)
        set_args_keys(state: '', protocol: protocol)
        config_set('vxlan_vtep_vni', 'ingress_replication', @set_args)
      end
    end

    def ingress_replication=(protocol)
      if protocol == default_ingress_replication
        set_args_keys(state: 'no', protocol: ingress_replication)
        config_set('vxlan_vtep_vni', 'ingress_replication', @set_args) unless
          ingress_replication == default_ingress_replication
      else
        remove_add_ingress_replication(protocol)
      end
    end

    def default_ingress_replication
      config_get_default('vxlan_vtep_vni', 'ingress_replication')
    end

    def multicast_group
      g1, g2 = config_get('vxlan_vtep_vni', 'multicast_group', @get_args)
      g2.nil? ? g1 : g1 + ' ' + g2
    end

    def remove_add_multicast_group(ip_start, ip_end)
      set_args_keys(state: 'no', ip_start: '', ip_end: '')
      config_set('vxlan_vtep_vni', 'multicast_group', @set_args)
      set_args_keys(state: '', ip_start: ip_start, ip_end: ip_end)
      config_set('vxlan_vtep_vni', 'multicast_group', @set_args)
    end

    def multicast_group=(range)
      if range == default_multicast_group
        set_args_keys(state: 'no', ip_start: '', ip_end: '')
        config_set('vxlan_vtep_vni', 'multicast_group', @set_args)
      else
        ip_start, ip_end = range.split(' ')
        ip_end = '' if ip_end.nil?
        remove_add_multicast_group(ip_start, ip_end)
      end
    end

    def default_multicast_group
      config_get_default('vxlan_vtep_vni', 'multicast_group')
    end

    def peer_list
      config_get('vxlan_vtep_vni', 'peer_list', @get_args)
    end

    def peer_list=(should_list)
      delta_hash = Utils.delta_add_remove(should_list, peer_list)
      return if delta_hash.values.flatten.empty?
      [:add, :remove].each do |action|
        CiscoLogger.debug('peer_list' \
          "#{@get_args}\n #{action}: #{delta_hash[action]}")
        delta_hash[action].each do |peer|
          state = (action == :add) ? '' : 'no'
          @set_args[:state] = state
          @set_args[:peer] = peer
          config_set('vxlan_vtep_vni', 'peer_list', @set_args)
        end
      end
    end

    def default_peer_list
      config_get_default('vxlan_vtep_vni', 'peer_list')
    end

    def suppress_arp
      config_get('vxlan_vtep_vni', 'suppress_arp', @get_args)
    end

    def suppress_arp=(state)
      # Host reachability must be enabled for this property
      VxlanVtep.new(@name).host_reachability = 'evpn'
      set_args_keys(state: (state ? '' : 'no'))
      config_set('vxlan_vtep_vni', 'suppress_arp', @set_args)
    end

    def default_suppress_arp
      config_get_default('vxlan_vtep_vni', 'suppress_arp')
    end
  end
end
