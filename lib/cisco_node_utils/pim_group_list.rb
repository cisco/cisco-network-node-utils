# PIM feature
# Provides configuration of PIM configuration of rp-addresses with group-lists
#
# Smitha Gopalan, November 2015
#
# Copyright (c) 2014-2015 Cisco and/or its affiliates.
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
#-------------------------------------------------------------------------------
# CLI: ip pim rp-address <rp-address> group-list <group> (under different VRFs)
#-------------------------------------------------------------------------------

require_relative 'node_util'
require 'pp'

module Cisco
  # node_utils class for pim grouplist
  class PimGroupList < NodeUtil
    attr_reader :rp_addr, :vrf, :group

    # Constructor with grouplist and vrf
    # ----------------------------------
    def initialize(rp_addr, group, vrf='default', instantiate=true)
      fail ArgumentError unless vrf.is_a? String
      fail ArgumentError unless vrf.length > 0
      @rp_addr = rp_addr
      @group = group
      @vrf = vrf
      if @vrf == 'default'
        @get_args = @set_args = { state: '', addr: @rp_addr, group: @group }
      else
        @get_args = @set_args = { state: '', addr: @rp_addr,
                                  vrf: @vrf, group: @group }
      end
      create if instantiate
    end

    # Create a hash of [rp-addr,grouplist]=>vrf mappings
    # --------------------------------------------------
    def self.group_lists
      hash_final = {}
      rp_addrs = config_get('pim_rp_address', 'all_group_lists')
      return hash_final if rp_addrs.nil?
      rp_addrs.each do |addr_and_group|
        # Get the RPs under default VRF
        addr = addr_and_group[0]
        group = addr_and_group[1]
        hash_final[addr_and_group] = {}
        hash_final[addr_and_group]['default'] = PimGroupList.new(addr, group,
                                                                 'default',
                                                                 false)
      end
      # Getting all custom vrfs rp_Addrs
      vrf_ids = config_get('vrf', 'all_vrfs')
      vrf_ids.delete_if { |vrf_id| vrf_id == 'management' }
      vrf_ids.each do |vrf|
        get_args = { rp_addr: @rp_addr, vrf: @vrf, group: @group }
        get_args[:vrf] = vrf
        rpaddrs = config_get('pim_rp_address', 'all_group_lists', get_args)
        next if rpaddrs.nil?
        rpaddrs.each do |addr_and_group|
          addr = addr_and_group[0]
          group = addr_and_group[1]
          hash_final[addr_and_group] ||= {}
          hash_final[addr_and_group][vrf] = PimGroupList.new(addr, group,
                                                             vrf, false)
        end
      end
      puts 'FINAL HASH is: '
      pp '-------------'
      # pp hash_final
      hash_final
    end

    # set_args_keys_default
    # ---------------------
    def set_args_keys_default
      keys = { addr: @rp_addr, vrf: @vrf, group: @group }
      @get_args = @set_args = keys
    end

    # set_args_key
    # -------------
    def set_args_keys(hash={}) # rubocop:disable Style/AccessorMethodName
      set_args_keys_default
      @set_args = @get_args.merge!(hash) unless hash.empty?
    end

    # Enable Feature pim
    # -------------------
    def enable
      config_set('pim_rp_address', 'feature')
    end

    # Check if feature pim is enabled
    # -------------------------------
    def self.enabled
      feature_state = config_get('pim_rp_address', 'feature')
      return !(feature_state.nil? || feature_state.empty?)
    rescue Cisco::CliError => e
      return false if e.clierror =~ /Syntax error/
      raise
    end

    # Create pim grouplist instance
    # ---------------------------------
    def create
      PimGroupList.enable unless PimGroupList.enabled
      config_set('pim_rp_address', 'group_list', @set_args)
    end

    # Destroy pim grouplist instance
    # ----------------------------------
    def destroy
      set_args_keys(state: 'no')
      if @set_args.include?(:vrf) && @set_args[:vrf] == 'default'
        @set_args.delete(:vrf)
      end
      config_set('pim_rp_address', 'group_list', @set_args)
    end
  end
end
