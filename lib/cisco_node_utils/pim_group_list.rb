# NXAPI implementation of the PimGroupList class
#
# Smitha Gopalan, November 2015
#
# Copyright (c) 2014-2016 Cisco and/or its affiliates.
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
require_relative 'pim'

module Cisco
  # node_utils class for pim grouplist
  class PimGroupList < NodeUtil
    attr_reader :afi, :rp_addr, :group, :vrf

    # Constructor with grouplist and vrf
    # ----------------------------------
    def initialize(afi, vrf, rp_addr, group, instantiate=true)
      fail ArgumentError unless vrf.is_a?(String) || vrf.length > 0
      @afi = Pim.afi_cli(afi)
      @rp_addr = rp_addr
      @group = group
      @vrf = vrf
      set_args_keys_default

      create if instantiate
    end

    # Create a hash of [afi][vrf][rp-addr,grouplist]
    # --------------------------------------------------
    def self.group_lists
      afis = %w(ipv4) # TBD ipv6
      hash = {}
      afis.each do |afi|
        hash[afi] = {}
        default_vrf = 'default'
        get_args = { afi: Pim.afi_cli(afi) }
        rp_addrs = config_get('pim', 'all_group_lists', get_args)
        unless rp_addrs.nil?
          rp_addrs.each do |addr_and_group|
            addr, group = addr_and_group
            hash[afi][default_vrf] ||= {}
            hash[afi][default_vrf][addr_and_group] =
              PimGroupList.new(afi, default_vrf, addr, group, false)
          end
        end
        vrf_ids = config_get('vrf', 'all_vrfs')
        vrf_ids.each do |vrf|
          get_args = { vrf: vrf, afi: Pim.afi_cli(afi) }
          rp_addrs = config_get('pim', 'all_group_lists', get_args)
          next if rp_addrs.nil?
          rp_addrs.each do |addr_and_group|
            hash[afi][vrf] ||= {}
            addr, group = addr_and_group
            hash[afi][vrf][addr_and_group] =
              PimGroupList.new(afi, vrf, addr, group, false)
          end
        end
      end
      hash
    rescue Cisco::CliError => e
      # cmd will syntax reject when feature is not enabled
      raise unless e.clierror =~ /Syntax error/
      return {}
    end

    # set_args_keys_default
    # ---------------------
    def set_args_keys_default
      keys = { afi: @afi, addr: @rp_addr, group: @group }
      keys[:vrf] = @vrf unless @vrf == 'default'
      @get_args = @set_args = keys
    end

    # set_args_key
    # -------------
    def set_args_keys(hash={}) # rubocop:disable Style/AccessorMethodName
      set_args_keys_default
      @set_args = @get_args.merge!(hash) unless hash.empty?
    end

    # Create pim grouplist instance
    # ---------------------------------
    def create
      Pim.feature_enable unless Pim.feature_enabled
      set_args_keys(state: '')
      config_set('pim', 'group_list', @set_args)
    end

    # Destroy pim grouplist instance
    # ----------------------------------
    def destroy
      set_args_keys(state: 'no')
      config_set('pim', 'group_list', @set_args)
    end
  end
end
