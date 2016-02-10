# VNI provider class
#
# Deepak Cherian, September 2015
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
#
# ----
# This provider supports both MT-full (N7K) and MT-lite (N3K/N9K),
# each of which have their own feature requirements and clis.
#
# MT-full cli:                      MT-lite cli:
#   feature nv overlay              feature nv overlay
#   feature nvi                     feature vn-segment-vlan-based
#   system bridge-domain 100-113
#   bridge-domain 100
#     member vni 100
#   vni 10001                       vlan 100
#     shutdown                        vn-segment 10001
#
require_relative 'node_util'
require_relative 'feature'

module Cisco
  # node_utils class for Vni
  class Vni < NodeUtil
    attr_reader :name, :vni_id

    def initialize(vni_id, instantiate=true)
      @vni_id = vni_id.to_s
      fail ArgumentError,
           'Invalid value(non-numeric VNI id)' unless @vni_id[/^\d+$/]
      create if instantiate
    end

    def self.vnis
      hash = {}
      vni_list = config_get('vni', 'all_vnis')
      return hash if vni_list.nil?

      vni_list.each do |id|
        hash[id] = Vni.new(id, false)
      end
      hash
    end

    # feature vni
    def self.feature_vni_enabled
      config_get('vni', 'feature')
    rescue Cisco::CliError => e
      # cmd will syntax reject when feature is not enabled
      raise unless e.clierror =~ /Syntax error/
      return false
    end

    def self.feature_vni_enable # TBD: move this to feature.rb
      Feature.nv_overlay_enable
      config_set('vni', 'feature')
    end

    def self.mt_full_support
      config_get('vni', 'mt_full_support')
    end

    def self.mt_lite_support
      config_get('vni', 'mt_lite_support')
    end

    def create
      Vni.feature_vni_enable unless Vni.feature_vni_enabled
      config_set('vni', 'create', vni: @vni_id) if Vni.mt_full_support
    end

    def destroy
      config_set('vni', 'destroy', vni: @vni_id)
    end

    def cli_error_check(result)
      # The NXOS vni cli does not raise an exception in some conditions and
      # instead just displays a STDOUT error message; thus NXAPI does not detect
      # the failure and we must catch it by inspecting the "body" hash entry
      # returned by NXAPI. This cli behavior is unlikely to change.
      fail result[2]['body'] if /ERROR:/.match(result[2]['body'].to_s)
    end

    # TODO: This method will be refactored as part of US52662
    # def encap_dot1q
    #  final_hash = {}
    #  show = show("sh encapsulation profile | inc 'vni [0-9,]*' p 1")
    #  debug("show class is #{show.class} and show op is #{show}")
    #  return final_hash if show == {}
    #  match_pat = /vni (\S+).*dot1q\s+([ 0-9,\-]+)vni ([ 0-9,\-]+)/m
    #  split_pat = /encapsulation profile /
    #  pair_arr = show.split(split_pat)
    #  pair_arr.each do |pair|
    #    match_arr = match_pat.match(pair)
    #    next if match_arr.nil?
    #    debug "match arr 1 : #{match_arr[1]} 2: #{match_arr[2]} " \
    #          "3: #{match_arr[3]}"
    #    key_arr = (match_arr[3].split(/,/)).map do |x|
    #      x.strip!
    #      if /-/.match(x)
    #        x.gsub!('-', '..')
    #      else
    #        x
    #      end
    #    end
    #    val_arr = (match_arr[2].split(/,/)).map do |x|
    #      x.strip!
    #      if /-/.match(x)
    #        x.gsub!('-', '..')
    #      else
    #        x
    #      end
    #    end
    #
    #    debug "key_arr = #{key_arr} val_arr = #{val_arr}"
    #
    #    index = 0
    #    value = nil
    #    key_arr.each do |key|
    #      # puts "checking |#{key}| against |#{@vni_id}|"
    #      # puts "checking #{key.class} against #{my_vni.class}"
    #      if /\.\./.match(key)
    #        range = eval(key) ###################### *MUSTFIX* REMOVE eval
    #        if range.include?(@vni_id.to_i)
    #          val_range = eval(val_arr[index]) ##### *MUSTFIX* REMOVE eval
    #          position = @vni_id.to_i - range.begin
    #          value = val_range.begin + position
    #          value = value.to_s
    #          debug "matched #{@vni_id} value is #{value}"
    #          break
    #        end
    #      elsif key == @vni_id
    #        value = val_arr[index]
    #        debug "matched #{key} value is #{value}"
    #      end
    #      index += 1
    #    end
    #    unless value.nil?
    #      # final_hash[match_arr[1]] = value.to_i
    #      final_hash[match_arr[1]] = value
    #    end
    #  end # pair.each
    #  final_hash
    # end # end of encap_dot1q

    def encap_dot1q=(val, prev_val=nil) # TBD REFACTOR
      debug "val is of class #{val.class} and is #{val} prev is #{prev_val}"
      # When prev_val is nil, HashDiff doesn't do a `+' on each element, so this
      if prev_val.nil?
        val.each do |fresh_profile, fresh_dot1q|
          config_set('vni', 'encap_dot1q', fresh_profile, '',
                     fresh_dot1q, @vni_id)
        end
        return
      end
      require 'hashdiff'
      hash_diff = HashDiff.diff(prev_val, val)
      debug "hsh diff ; #{hash_diff}"
      return if hash_diff == []
      hash_diff.each do |diff|
        result =
          case diff[0]
          when /\+/
            config_set('vni', 'encap_dot1q', diff[1], '', diff[2], @vni_id)
          when /\-/
            config_set('vni', 'encap_dot1q', diff[1], 'no', diff[2], @vni_id)
          when /~/
            config_set('vni', 'encap_dot1q', diff[1], 'no', diff[2], @vni_id)
            config_set('vni', 'encap_dot1q', diff[1], '', diff[3], @vni_id)
          end
        cli_error_check(result)
      end
    rescue CliError => e
      raise "[vni #{@vni_id}] '#{e.command}' : #{e.clierror}"
    end

    def default_encap_dot1q
      config_get_default('vni', 'encap_dot1q')
    end

    def bridge_domain
      bd_arr = config_get('vni', 'bridge_domain', vni: @vni_id)
      bd_arr.first.to_i
    end

    def bridge_domain=(domain)
      # TBD: ACTIVATE SHOULD BE SEPARATE SETTER AND POSSIBLY RENAMED
      state = (domain) ? '' : 'no'
      config_set('vni', 'bridge_domain_activate', state: state, domain: domain)
      config_set('vni', 'bridge_domain', state: state, domain: domain,
                 vni: @vni_id)
    end

    def default_bridge_domain
      config_get_default('vni', 'bridge_domain')
    end

    def shutdown
      config_get('vni', 'shutdown', vni: @vni_id)
    end

    def shutdown=(state)
      state = (state) ? '' : 'no'
      result = config_set('vni', 'shutdown', state: state, vni: @vni_id)
      cli_error_check(result)
    rescue CliError => e
      raise "[vni #{@vni_id}] '#{e.command}' : #{e.clierror}"
    end

    def default_shutdown
      config_get_default('vni', 'shutdown')
    end
  end # class
end # module
