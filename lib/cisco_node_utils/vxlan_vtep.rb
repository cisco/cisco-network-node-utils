#
# NXAPI implementation of VXLAN_VTEP class
#
# November 2015, Deepak Cherian
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

require File.join(File.dirname(__FILE__), 'node_util')

module Cisco
  # node_utils class for vxlan_vtep
  class VxlanVtep < NodeUtil
    attr_reader :name

    def initialize(name, instantiate=true)
      fail TypeError unless name.is_a?(String)
      fail ArgumentError unless name.length > 0
      @name = name.downcase

      create if instantiate
    end

    def self.vteps
      hash = {}
      is_vxlan_feature = config_get('vxlan', 'feature')
      return hash if (:enabled != is_vxlan_feature.first.to_sym)
      vtep_list = config_get('vxlan_vtep', 'all_interfaces')
      return hash if vtep_list.nil?

      vtep_list.each do |id|
        id = id.downcase
        hash[id] = VxlanVtep.new(id, false)
      end
      hash
    end

    def vxlan_feature
      vxlan = config_get('vxlan', 'feature')
      fail 'vxlan/nv_overlay feature not found' if vxlan.nil?
      return :disabled if vxlan.nil?
      vxlan.first.to_sym
    end

    def vxlan_feature_set(vxlan_set)
      curr = vxlan_feature
      return if curr == vxlan_set

      case vxlan_set
      when :enabled
        config_set('vxlan', 'feature', '')
      when :disabled
        config_set('vxlan', 'feature', 'no') if curr == :enabled
        return
      end
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def create
      unless (:enabled == vxlan_feature)
        vdc_name = config_get('limit_resource', 'vdc')
        @apply_to = vdc_name.first
        debug("###### VDC is #{@apply_to}")
        config_set('limit_resource', 'vxlan', @apply_to)
        vxlan_feature_set(:enabled)
      end
      # re-use the "interface command ref hooks"
      config_set('interface', 'create', @name)
    end

    def destroy
      # re-use the "interface command ref hooks"
      config_set('interface', 'destroy', @name)
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    def description
      desc = config_get('interface', 'description', @name)
      return '' if desc.nil?
      desc.shift.strip
    end

    def description=(desc)
      fail TypeError unless desc.is_a?(String)
      if desc.empty?
        config_set('interface', 'description', @name, 'no', '')
      else
        config_set('interface', 'description', @name, '', desc)
      end
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def default_description
      config_get_default('interface', 'description')
    end

    def vni_mcast_grp_map
      final_hash = {}
      show = show("show running-config interface #{@name}")
      debug("show class is #{show.class} and show op is #{show}")
      return final_hash if show == {}
      match_pat1 = /vni\s+(\S+).*mcast\-group\s+(\S+)/m
      match_pat2 = /vni\s+(\S+).*(associate\-vrf)/m
      split_pat = /member\s+/
      pair_arr = show.split(split_pat)
      pair_arr.each do |pair|
        match_arr = match_pat1.match(pair)
        match_arr ||= match_pat2.match(pair)
        unless match_arr.nil?
          debug "match arr 1 : #{match_arr[1]} 2: #{match_arr[2]}"
          final_hash[match_arr[1]] = "#{match_arr[2]}"
        end
      end
      final_hash
    end

    def vni_mcast_grp_map=(val, prev_val=nil)
      debug "val is of class #{val.class} and is #{val} prev is #{prev_val}"
      # When prev_val is nil, HashDiff doesn't do a `+' on each element, so this
      debug "value of mac_dist = #{@mac_dist_proto}"
      param_hash = {}
      # supress_arp = (@mac_dist_proto == :evpn) ? "supress-arp" : ""
      if prev_val.nil?
        val.each do |fresh_vni, fresh_mgrp|
          param_hash = { name: @name, no_cmd: '', vni: fresh_vni,
                         mcast_grp: fresh_mgrp }
          config_set('vxlan_vtep', 'member_vni_mgrp', param_hash)
        end
        return
      end
      require 'hashdiff'
      hash_diff = HashDiff.diff(prev_val, val)
      debug "hsh diff ; #{hash_diff}"
      return if hash_diff == []
      hash_diff.each do |diff|
        case diff[0]
        when /\+/
          param_hash = { name: @name, no_cmd: '', vni: diff[1],
                         mcast_grp: diff[2] }
        when /\-/
          param_hash = { name: @name, no_cmd: 'no', vni: diff[1],
                         mcast_grp: diff[2] }
        when /~/
          param_hash = { name: @name, no_cmd: 'no', vni: diff[1],
                         mcast_grp: diff[2] }
          config_set('vxlan_vtep', 'member_vni_mgrp', param_hash)
          param_hash = { name: @name, no_cmd: '', vni: diff[1],
                         mcast_grp: diff[3] }
        end
        config_set('vxlan_vtep', 'member_vni_mgrp', param_hash)
      end
    rescue CliError => e
      raise "[vxlan_vtep #{@name}] '#{e.command}' : #{e.clierror}"
    end

    def mac_distribution
      mac_dist = config_get('vxlan_vtep', 'mac_distribution', name: @name)
      debug "mac_dist is #{mac_dist}"
      if mac_dist.nil?
        @mac_dist_proto = :flood
      else
        @mac_dist_proto = (mac_dist.first.strip == 'bgp') ? :evpn : :flood
      end
      @mac_dist_proto.to_s
    end

    def mac_distribution=(val)
      debug "mac_distrib val is #{val} and class is #{val.class}"
      if val == :flood
        if @mac_dist_proto == :evpn
          config_set('vxlan_vtep', 'mac_distribution',
                     name: @name, no_cmd: 'no', proto: 'bgp')
        end
        @mac_dist_proto = :flood
      elsif val == :evpn
        config_set('vxlan_vtep', 'mac_distribution',
                   name: @name, no_cmd: '', proto: 'bgp')
        @mac_dist_proto = :evpn
      end
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def source_interface
      src_intf = config_get('vxlan_vtep', 'source_intf', name: @name)
      debug "src_intf is #{src_intf}"
      return '' if src_intf.nil?
      src_intf.first.strip
    end

    def source_interface=(val)
      fail TypeError unless val.is_a?(String)
      if val.empty?
        config_set('vxlan_vtep', 'source_intf',
                   name: @name, no_cmd: 'no', lpbk_intf: val)
      else
        config_set('vxlan_vtep', 'source_intf',
                   name: @name, no_cmd: '', lpbk_intf: val)
      end
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def shutdown
      state = config_get('interface', 'shutdown', @name)
      state ? true : false
    end

    def shutdown=(state)
      no_cmd = (state ? '' : 'no')
      config_set('interface', 'shutdown', @name, no_cmd)
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def default_shutdown
      false
    end
  end  # Class
end    # Module
