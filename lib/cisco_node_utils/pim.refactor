#
# NXAPI implementation of PIM class
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
  # node_utils class for Pim
  class Pim < NodeUtil
    attr_reader :name

    def initialize(name, instantiate=true)
      fail TypeError unless name.is_a?(String)
      fail ArgumentError unless name.length > 0
      @name = name.downcase

      create if instantiate
    end

    def self.pims
      hash = {}
      feature = config_get('pim', 'feature')
      return hash if (:enabled != feature.first.to_sym)
      pim_list = config_get('pim', 'all_pim')
      if !pim_list.nil?
        pim_list = ['default']
      else
        pim_list = []
      end
      # vrf_pim_list = config_get("pim", "all_pim_vrf")
      show = show("sh run pim all | inc '^vrf'")
      vrf_pim_list = []
      if !show.nil? && show != {}
        vrf_pim_list = show.split(/\n/).map do |elem|
          match_arr = /\s+context\s+(\S+)/.match(elem)
          match_arr[1]
        end
      end
      pim_list.push(*vrf_pim_list)
      return hash if pim_list.nil?

      pim_list.each do |id|
        id = id.downcase
        hash[id] = Pim.new(id, false)
      end
      hash
    end

    def pim_feature
      pim = config_get('pim', 'feature')
      fail 'pim feature not found' if pim.nil?
      return :disabled if pim.nil?
      pim.first.to_sym
    end

    def pim_feature_set(pim_set)
      curr = pim_feature
      return if curr == pim_set

      case pim_set
      when :enabled
        config_set('pim', 'feature', '')
      when :disabled
        config_set('pim', 'feature', 'no') if curr == :enabled
        return
      end
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def create
      pim_feature_set(:enabled) unless (:enabled == pim_feature)
    end

    def destroy
      pim_feature_set(:disabled)
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    def rp_list
      final_hash = {}
      if @name == 'default'
        rp_list_array = config_get('pim', 'rp_list')
      else
        rp_list_array = config_get('pim', 'rp_list_vrf', @name)
      end
      final_hash = rp_list_array.to_h unless rp_list_array.nil?
      final_hash
    end

    def rp_list=(val, prev_val=nil)
      debug "val is of class #{val.class} and is #{val} prev is #{prev_val}"
      # When prev_val is nil, HashDiff doesn't do a `+' on each element, so this
      if prev_val.nil?
        val.each do |fresh_rp, fresh_mgrp|
          if @name == 'default'
            splat_args = ['pim', 'rp_list', '', fresh_rp, fresh_mgrp]
          else
            splat_args = ['pim', 'rp_list_vrf', @name, '', fresh_rp, fresh_mgrp]
          end
          config_set(*splat_args)
        end
        return
      end
      require 'hashdiff'
      hash_diff = HashDiff.diff(prev_val, val)
      debug "hsh diff ; #{hash_diff}"
      return if hash_diff == []
      if @name == 'default'
        splat_args = %w(pim rp_list)
      else
        splat_args = ['pim', 'rp_list_vrf', @name]
      end
      hash_diff.each do |diff|
        case diff[0]
        when /\+/
          splat_args.push '', diff[1], diff[2]
        when /\-/
          splat_args.push 'no', diff[1], diff[2]
        when /~/
          new_splat_args = splat_args + ['no', diff[1], diff[2]]
          config_set(*new_splat_args)
          splat_args.push '', diff[1], diff[3]
        end
        config_set(*splat_args)
      end
    rescue CliError => e
      raise "[vxlan_vtep #{@name}] '#{e.command}' : #{e.clierror}"
    end

    def ssm_range
      if @name == 'default'
        ssm_range_arr = config_get('pim', 'ssm_range')
      else
        ssm_range_arr = config_get('pim', 'ssm_range_vrf', @name)
      end
      debug "ssm_range is #{ssm_range_arr}"
      return '' if ssm_range_arr.nil?
      ssm_range_arr.first.strip
    end

    def ssm_range=(val)
      fail TypeError unless val.is_a?(String)
      if @name == 'default'
        splat_args = %w(pim ssm_range)
      else
        splat_args = ['pim', 'ssm_range_vrf', @name]
      end
      if val.empty?
        splat_args.push('no', val)
      else
        splat_args.push('', val)
      end
      config_set(*splat_args)
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end
  end  # Class
end    # Module
