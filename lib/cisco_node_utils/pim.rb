# PIM feature
# Provides configuration of PIM and its various properties
# like ssm-range, etc
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
#-------------------------------------------------------
# CLI: ip pim ssm-range <range>  (under different VRFs)
#-------------------------------------------------------

require_relative 'node_util'

module Cisco
  # node_utils class for Pim
  class Pim < NodeUtil
    attr_reader :vrf

    # Constructor with vrf
    # ---------------------
    def initialize(vrf='default', instantiate=true)
      fail ArgumentError unless vrf.is_a? String
      fail ArgumentError unless vrf.length > 0
      @vrf = vrf
      if @vrf == 'default'
        @get_args = @set_args = { state: '' }
      else
        @get_args = @set_args = { state: '', vrf: @vrf }
      end
<<<<<<< HEAD
      enable if instantiate
    end

    # Set afi
    # --------
    def self.afi_cli(afi)
      # Add ipv6 support later
      fail ArgumentError, "Argument afi must be 'ipv4'" unless
        afi[/(ipv4)/]
      afi[/ipv4/] ? 'ip' : afi
=======
      enable if instantiate && !Pim.enabled
>>>>>>> parent of e4346a1... NXAPI Implementation & Mini Tests for Pim
    end

    # set_args_keys_default
    # ----------------------
    def set_args_keys_default
      keys = { vrf: @vrf }
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
      config_set('pim', 'feature')
    end

    # Check Feature pim state
    # --------------------------
    def self.enabled
      feature_state = config_get('pim', 'feature')
      return !(feature_state.nil? || feature_state.empty?)
    rescue Cisco::CliError => e
      return false if e.clierror =~ /Syntax error/
      raise
    end

    # Properties:
    #-----------

    # ssm_range : getter
    # -------------------
    def ssm_range
      ranges = config_get('pim', 'ssm_range', @get_args)
      ranges.split(' ').sort
    end

    # ssm_range : setter
    # -------------------
    def ssm_range=(range)
<<<<<<< HEAD
      set_args_keys(state: '', ssm_range: range)
=======
      @set_args[:ssm_range] = range
>>>>>>> parent of e4346a1... NXAPI Implementation & Mini Tests for Pim
      config_set('pim', 'ssm_range', @set_args)
    end
  end
end
