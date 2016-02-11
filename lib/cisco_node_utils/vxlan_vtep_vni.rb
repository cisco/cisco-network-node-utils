#
# NXAPI implementation of VxlanVtepVni class
#
# November 2015 Michael G Wiebe
#
# Copyright (c) 2015-2016 Cisco and/or its affiliates.
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
    attr_reader :name, :vni, :assoc_vrf

    def initialize(name, vni, assoc_vrf=false, instantiate=true)
      @name = name
      @vni = vni
      @assoc_vrf = assoc_vrf

      set_args_keys_default
      create if instantiate
    end

    def self.vnis
      hash = {}
      VxlanVtep.vteps.each do |name, _obj|
        hash[name] = {}
        get_args = { name: name }
        vni_list = config_get('vxlan_vtep_vni', 'all_vnis', get_args)
        next if vni_list.nil?
        vni_list.each do |vni, assoc_vrf|
          assoc_vrf = assoc_vrf.nil? ? false : true
          hash[name][vni] = VxlanVtepVni.new(name, vni, assoc_vrf, false)
        end
      end
      hash
    end

    def ==(other)
      (name == other.name) && (vni == other.vni) &&
        (assoc_vrf == other.assoc_vrf)
    end

    def set_args_keys_default
      keys = { name: @name, vni: @vni }
      keys[:assoc_vrf] = @assoc_vrf ? 'associate-vrf' : ''
      @get_args = @set_args = keys
    end

    # rubocop:disable Style/AccessorMethodName
    def set_args_keys(hash={})
      set_args_keys_default
      @set_args = @get_args.merge!(hash) unless hash.empty?
    end
    # rubocop:enable Style/AccessorMethodNamefor

    def create_with_associate_vrf?
      !@set_args[:assoc_vrf].eql?('')
    end

    def destroy_existing(key)
      getargs = { name: @name, vni: @vni, state: '' }
      return unless config_get('vxlan_vtep', key, getargs)
      getargs[:assoc_vrf] = key.eql?('vni_with_vrf') ? 'associate-vrf' : ''
      getargs[:state] = 'no'
      config_set('vxlan_vtep', 'vni', getargs)
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
        # first remove the existing protocol.
        set_args_keys(state: 'no', protocol: ingress_replication)
        config_set('vxlan_vtep_vni', 'ingress_replication', @set_args)
        set_args_keys(state: '', protocol: protocol)
        config_set('vxlan_vtep_vni', 'ingress_replication', @set_args)
      end
    end

    def ingress_replication=(protocol)
      return if protocol.to_s == ingress_replication
      # Only set ingress_replicatin to the default value if it's not already.
      if protocol.to_s == default_ingress_replication &&
         (ingress_replication != default_ingress_replication)
        set_args_keys(state: 'no', protocol: ingress_replication)
        config_set('vxlan_vtep_vni', 'ingress_replication', @set_args)
      else
        # Multicast group and ingress replication are mutually exclusive
        # properties, so remove multicast_group first
        unless multicast_group.empty?
          set_args_keys(state: 'no', ip_start: '', ip_end: '')
          config_set('vxlan_vtep_vni', 'multicast_group', @set_args)
        end
        remove_add_ingress_replication(protocol.to_s)
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
        # Due to CSCux78514, trying to remove multicast-group in CLI
        # when ingress replication is configured results in removing
        # ingress replication from nvgen. So be careful and negate
        # Multicast-group only is it is configured.
        unless multicast_group.empty?
          set_args_keys(state: 'no', ip_start: '', ip_end: '')
          config_set('vxlan_vtep_vni', 'multicast_group', @set_args)
        end
      else
        ip_start, ip_end = range.split(' ')
        ip_end = '' if ip_end.nil?
        # Since multicast group and ingress replication are exclusive
        # properties, remove ingress replication first
        unless ingress_replication.empty?
          set_args_keys(state: 'no', protocol: ingress_replication)
          config_set('vxlan_vtep_vni', 'ingress_replication', @set_args)
        end
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
      if state
        set_args_keys(state: '')
        # Host reachability must be enabled for this property
        VxlanVtep.new(@name).host_reachability = 'evpn'
        config_set('vxlan_vtep_vni', 'suppress_arp', @set_args)
      else
        set_args_keys(state: 'no')
        # Remove suppress-arp only if it is configured. Suppress-arp needs
        # free TCAM region for arp-ether ACL. Customers who don't need
        # suppress-arp, needn't see cli failures warning about TCAM regions
        # issued due to 'no suppress-arp'. Note that for suppress-arp, default
        # is 'false' which is no suppress-arp
        config_set('vxlan_vtep_vni', 'suppress_arp', @set_args) if suppress_arp
      end
    end

    def default_suppress_arp
      config_get_default('vxlan_vtep_vni', 'suppress_arp')
    end
  end
end
