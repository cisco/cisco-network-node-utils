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

require_relative 'node_util'

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
      return hash unless feature_enabled
      vtep_list = config_get('vxlan_vtep', 'all_interfaces')
      return hash if vtep_list.nil?

      vtep_list.each do |id|
        id = id.downcase
        hash[id] = VxlanVtep.new(id, false)
      end
      hash
    end

    def self.feature_enabled
      config_get('vxlan', 'feature')
    rescue Cisco::CliError => e
      # cmd will syntax when feature is not enabled.
      raise unless e.clierror =~ /Syntax error/
      return false
    end

    def self.enable(state='')
      config_set('vxlan', 'feature', state: state)
    end

    def create
      unless VxlanVtep.feature_enabled
        # Only supported on n7k currently.
        vdc_name = config_get('limit_resource', 'vdc')
        config_set('limit_resource', 'vxlan', vdc_name) unless vdc_name.nil?
        VxlanVtep.enable
      end
      # re-use the "interface command ref hooks"
      config_set('interface', 'create', @name)
    end

    def destroy
      # re-use the "interface command ref hooks"
      config_set('interface', 'destroy', @name)
    end

    def ==(other)
      name == other.name
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    def description
      config_get('interface', 'description', @name)
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

    # TODO: Move vni_mcast_grp_map to vxlan_vtp_vni.rb object
    #
    # def vni_mcast_grp_map
    #  final_hash = {}
    #  show = show("show running-config interface #{@name}")
    #  debug("show class is #{show.class} and show op is #{show}")
    #  return final_hash if show == {}
    #  match_pat1 = /vni\s+(\S+).*mcast\-group\s+(\S+)/m
    #  match_pat2 = /vni\s+(\S+).*(associate\-vrf)/m
    #  split_pat = /member\s+/
    #  pair_arr = show.split(split_pat)
    #  pair_arr.each do |pair|
    #    match_arr = match_pat1.match(pair)
    #    match_arr ||= match_pat2.match(pair)
    #    unless match_arr.nil?
    #      debug "match arr 1 : #{match_arr[1]} 2: #{match_arr[2]}"
    #      final_hash[match_arr[1]] = "#{match_arr[2]}"
    #    end
    #  end
    #  final_hash
    # end

    # TODO: Move vni_mcast_grp_map to vxlan_vtp_vni.rb object
    #
    # def vni_mcast_grp_map=(val, prev_val=nil)
    #  debug "val is of class #{val.class} and is #{val} prev is #{prev_val}"
    #  # When prev_val is nil, HashDiff doesn't do a `+' on each element, so
    #  # this
    #  debug "value of mac_dist = #{@mac_dist_proto}"
    #  param_hash = {}
    #  # supress_arp = (@mac_dist_proto == :evpn) ? "supress-arp" : ""
    #  if prev_val.nil?
    #    val.each do |fresh_vni, fresh_mgrp|
    #      param_hash = { name: @name, no_cmd: '', vni: fresh_vni,
    #                     mcast_grp: fresh_mgrp }
    #      config_set('vxlan_vtep', 'member_vni_mgrp', param_hash)
    #    end
    #    return
    #  end
    #  require 'hashdiff'
    #  hash_diff = HashDiff.diff(prev_val, val)
    #  debug "hsh diff ; #{hash_diff}"
    #  return if hash_diff == []
    #  hash_diff.each do |diff|
    #    case diff[0]
    #    when /\+/
    #      param_hash = { name: @name, no_cmd: '', vni: diff[1],
    #                     mcast_grp: diff[2] }
    #    when /\-/
    #      param_hash = { name: @name, no_cmd: 'no', vni: diff[1],
    #                     mcast_grp: diff[2] }
    #    when /~/
    #      param_hash = { name: @name, no_cmd: 'no', vni: diff[1],
    #                     mcast_grp: diff[2] }
    #      config_set('vxlan_vtep', 'member_vni_mgrp', param_hash)
    #      param_hash = { name: @name, no_cmd: '', vni: diff[1],
    #                     mcast_grp: diff[3] }
    #    end
    #    config_set('vxlan_vtep', 'member_vni_mgrp', param_hash)
    #  end
    # rescue CliError => e
    #  raise "[vxlan_vtep #{@name}] '#{e.command}' : #{e.clierror}"
    # end

    def mac_distribution
      mac_dist = config_get('vxlan_vtep', 'mac_distribution', name: @name)
      if mac_dist.nil?
        @mac_dist_proto = :flood
      else
        @mac_dist_proto = (mac_dist == 'bgp') ? :evpn : :flood
      end
      @mac_dist_proto.to_s
    end

    def mac_distribution=(val)
      if val == :flood
        if @mac_dist_proto == :evpn
          config_set('vxlan_vtep', 'mac_distribution',
                     name: @name, state: 'no', proto: 'bgp')
        end
        @mac_dist_proto = :flood
      elsif val == :evpn
        config_set('vxlan_vtep', 'mac_distribution',
                   name: @name, state: '', proto: 'bgp')
        @mac_dist_proto = :evpn
      end
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def source_interface
      src_intf = config_get('vxlan_vtep', 'source_intf', name: @name)
      return default_source_interface if src_intf.nil?
      src_intf
    end

    def source_interface=(val)
      fail TypeError unless val.is_a?(String)
      if val.empty?
        config_set('vxlan_vtep', 'source_intf',
                   name: @name, state: 'no', lpbk_intf: val)
      else
        config_set('vxlan_vtep', 'source_intf',
                   name: @name, state: '', lpbk_intf: val)
      end
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def default_source_interface
      config_get_default('vxlan_vtep', 'source_intf')
    end

    def shutdown
      state = config_get('interface', 'shutdown', @name)
      state ? true : false
    end

    def shutdown=(bool)
      state = (bool ? '' : 'no')
      config_set('interface', 'shutdown', @name, state)
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def default_shutdown
      false
    end
  end  # Class
end    # Module
