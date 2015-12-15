# PIM feature
# Provides configuration of PIM configuration with rp-addresses
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
# CLI: ip pim rp-address <rp-address> (under different VRFs)
#------------------------------------------------------------

require_relative 'node_util'
require 'pp'

module Cisco
  # node_utils class for pim_rp_address
  class PimRpAddress < NodeUtil
    attr_reader :rp_addr, :vrf

    # Constructor with rp_address and vrf
    # --------------------------------------
    def initialize(rp_addr, vrf='default', instantiate=true)
      fail ArgumentError unless vrf.is_a? String
      fail ArgumentError unless vrf.length > 0
      @rp_addr = rp_addr
      @vrf = vrf
      if @vrf == 'default'
        @get_args = @set_args = { state: '', addr: @rp_addr }
      else
        @get_args = @set_args = { state: '', addr: @rp_addr, vrf: @vrf }
      end
      create if instantiate
    end

    # Create a hash of rp_address=>vrf mappings
    # --------------------------------------------
    def self.rp_addresses
      hash_final = {}
      rp_addrs = config_get('pim_rp_address', 'all_rp_addresses')
      return hash_final if rp_addrs.nil?

      # Get the RPs under default VRF
      rp_addrs.each do |addr|
        hash_final[addr] = {}
        hash_final[addr]['default'] = PimRpAddress.new(addr, 'default', false)
      end
      # Getting all custom vrfs rp_Addrs"
      vrf_ids = config_get('vrf', 'all_vrfs')
      vrf_ids.delete_if { |vrf_id| vrf_id == 'management' }
      vrf_ids.each do |vrf|
        get_args = { rp_addr: @rp_addr, vrf: @vrf }
        get_args[:vrf] = vrf
        rp_addrs = config_get('pim_rp_address', 'all_rp_addresses', get_args)
        next if rp_addrs.nil?
        rp_addrs.each do |addr|
          hash_final[addr] ||= {}
          hash_final[addr][vrf] = PimRpAddress.new(addr, vrf, false)
        end
      end
      puts 'FINAL HASH is: '
      pp '-------------'
      pp hash_final
    end

    # set_args_keys_default
    # ----------------------
    def set_args_keys_default
      keys = { addr: @rp_addr, vrf: @vrf }
      @get_args = @set_args = keys
    end

    # set_args_key
    # -------------
    def set_args_keys(hash={}) # rubocop:disable Style/AccessorMethodName
      set_args_keys_default
      @set_args = @get_args.merge!(hash) unless hash.empty?
    end

    # Enable Feature pim
    # ---------------------
    def enable
      config_set('pim_rp_address', 'feature')
    end

    # Check Feature pim state
    # --------------------------
    def self.enabled
      feature_state = config_get('pim_rp_address', 'feature')
      return !(feature_state.nil? || feature_state.empty?)
    rescue Cisco::CliError => e
      return false if e.clierror =~ /Syntax error/
      raise
    end

    # Create pim rp_addr instance
    # ------------------------------
    def create
      PimRpAddress.enable unless PimRpAddress.enabled
      config_set('pim_rp_address', 'rp_address', @set_args)
    end

    # Destroy pim rp_addr instance
    # ------------------------------
    def destroy
      set_args_keys(state: 'no')
      if @set_args.include?(:vrf) && @set_args[:vrf] == 'default'
        @set_args.delete(:vrf)
      end
      config_set('pim_rp_address', 'rp_address', @set_args)
    end
  end
end
