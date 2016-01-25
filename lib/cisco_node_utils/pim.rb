#
# NXAPI implementation of PIM class
#
# Smitha Gopalan, November 2015
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
  # node_utils class for Pim
  class Pim < NodeUtil
    attr_reader :vrf, :afi

    # Constructor with vrf
    # ---------------------
    def initialize(afi, vrf, instantiate=true)
      fail ArgumentError unless vrf.is_a?(String) || vrf.length > 0
      @vrf = vrf
      @afi = Pim.afi_cli(afi)
      set_args_keys_default

      Pim.feature_enable if instantiate
    end

    def self.feature_enabled
      config_get('pim', 'feature')
    rescue Cisco::CliError => e
      # cmd will syntax reject when feature is not enabled
      raise unless e.clierror =~ /Syntax error/
      return false
    end

    def self.feature_enable
      config_set('pim', 'feature')
    end

    def self.pims
      afis = %w(ipv4) # Add ipv6 later
      hash_final = {}
      afis.each do |afi|
        hash_final[afi] = {}
        default_vrf = 'default'
        ranges = config_get('pim', 'all_ssm_ranges', afi: Pim.afi_cli(afi))
        unless ranges.nil?
          ranges.each do |range|
            # Get the RPs under default VRF
            hash_final[afi][default_vrf] =
                      Pim.new(afi, default_vrf, false)
            hash_final[afi][default_vrf].ssm_range = (range)
          end
        end
        # Getting all custom vrfs rp_Addrs"
        vrf_ids = config_get('vrf', 'all_vrfs')
        vrf_ids.delete_if { |vrf_id| vrf_id == 'management' }
        vrf_ids.each do |vrf|
          get_args = { vrf: @vrf, afi: Pim.afi_cli(afi) }
          get_args[:vrf] = vrf
          ranges = config_get('pim', 'all_ssm_ranges', get_args)
          next if ranges.nil?
          ranges.each do |addr|
            hash_final[afi] ||= {}
            hash_final[afi][vrf] =
                      Pim.new(afi, vrf, false)
            hash_final[afi][vrf].ssm_range = (addr)
          end
        end
      end
      hash_final
    rescue Cisco::CliError => e
      # cmd will syntax reject when feature is not enabled
      raise unless e.clierror =~ /Syntax error/
      return {}
    end

    def self.afi_cli(afi)
      # Add ipv6 support later
      fail ArgumentError, "Argument afi must be 'ipv4'" unless
        afi[/(ipv4)/]
      afi[/ipv4/] ? 'ip' : afi
    end

    def set_args_keys_default
      keys = { afi: @afi }
      keys[:vrf] = @vrf unless @vrf == 'default'
      @get_args = @set_args = keys
    end

    def set_args_keys(hash={}) # rubocop:disable Style/AccessorMethodName
      set_args_keys_default
      @set_args = @get_args.merge!(hash) unless hash.empty?
    end

    #-----------
    # Properties
    #-----------
    def ssm_range
      range = config_get('pim', 'ssm_range', @get_args)
      range.split.sort.join(' ')
    end

    def ssm_range=(range)
      if range.empty?
        state = 'no'
        range = ssm_range
      else
        state = ''
      end
      set_args_keys(state: state, ssm_range: range)
      config_set('pim', 'ssm_range', @set_args)
    end
  end  # Class
end    # Module
