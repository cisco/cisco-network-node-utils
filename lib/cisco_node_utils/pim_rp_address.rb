# NXAPI implementation of the PimRpAddress class
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
#------------------------------------------------------------
# CLI: <afi> pim rp-address <rp-address> (under different VRFs)
#------------------------------------------------------------

require_relative 'node_util'
require_relative 'pim'

module Cisco
  # node_utils class for pim_rp_address
  class PimRpAddress < NodeUtil
    attr_reader :afi, :rp_addr, :vrf

    # Constructor with afi, rp_address and vrf
    # -----------------------------------------
    def initialize(afi, rp_addr, vrf='default', instantiate=true)
      fail ArgumentError unless vrf.is_a? String
      fail ArgumentError unless vrf.length > 0
      @afi = Pim.afi_cli(afi)
      @rp_addr = rp_addr
      @vrf = vrf
      if @vrf == 'default'
        @get_args = @set_args = { state: '', afi: @afi, addr: @rp_addr }
      else
        @get_args = @set_args =
                    { state: '', afi: @afi, addr: @rp_addr, vrf: @vrf }
      end
      create if instantiate
    end

    # Create a hash of [afi,rp_address]=>vrf mappings
    # ------------------------------------------------
    def self.rp_addresses
      afis = %w(ipv4) # Add ipv6 later
      hash_final = {}
      afis.each do |afi|
        hash_final[afi] = {}
        default_vrf = 'default'
        rp_addrs = config_get('pim', 'all_rp_addresses', afi: Pim.afi_cli(afi))
        unless rp_addrs.nil?
          rp_addrs.each do |addr|
            # Get the RPs under default VRF
            hash_final[afi][addr] = {}
            hash_final[afi][addr][default_vrf] =
                      PimRpAddress.new(afi, default_vrf, addr, false)
          end
        end
        # Getting all custom vrfs rp_Addrs"
        vrf_ids = config_get('vrf', 'all_vrfs')
        vrf_ids.delete_if { |vrf_id| vrf_id == 'management' }
        vrf_ids.each do |vrf|
          get_args = { rp_addr: @rp_addr, vrf: @vrf, afi: Pim.afi_cli(afi) }
          get_args[:vrf] = vrf
          rp_addrs = config_get('pim', 'all_rp_addresses', get_args)
          next if rp_addrs.nil?
          rp_addrs.each do |addr|
            hash_final[afi][addr] ||= {}
            hash_final[afi][addr][vrf] =
                      PimRpAddress.new(afi, vrf, addr, false)
          end
        end
      end
      hash_final
    end

    # set_args_keys_default
    # ----------------------
    def set_args_keys_default
      keys = { afi: @afi, addr: @rp_addr }
      keys[:vrf] = @vrf unless @vrf == 'default'
      @get_args = @set_args = keys
    end

    # set_args_key
    # -------------
    def set_args_keys(hash={}) # rubocop:disable Style/AccessorMethodName
      set_args_keys_default
      @set_args = @get_args.merge!(hash) unless hash.empty?
    end

    # Create pim rp_addr instance
    # ------------------------------
    def create
      Pim.enable unless Pim.enabled
      config_set('pim', 'rp_address', @set_args)
    end

    # Destroy pim rp_addr instance
    # ------------------------------
    def destroy
      set_args_keys(state: 'no')
      config_set('pim', 'rp_address', @set_args)
    end
  end
end
