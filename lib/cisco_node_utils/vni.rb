# VNI provider class
#
# Deepak Cherian, September 2015
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

require File.join(File.dirname(__FILE__), 'node_util')

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
      if /N9K/.match(node.product_id)
        feature = config_get('vni', 'feature_n9k')
        return hash if feature.nil?
        vni_list = config_get('vni', 'all_vnis_n9k')
      else
        feature = config_get('vni', 'feature')
        return hash if (:enabled != feature.to_sym)
        vni_list = config_get('vni', 'all_vnis')
      end
      return hash if vni_list.nil? || vni_list == {}

      vni_list.each do |id|
        hash[id] = Vni.new(id, false)
      end
      hash
    end

    def feature
      if /N9K/.match(node.product_id)
        vni = config_get('vni', 'feature_n9k')
      else
        vni = config_get('vni', 'feature')
      end
      return :disabled if vni.nil?
      :enabled
    end

    def feature_set(vni_set)
      curr = feature
      return if curr == vni_set

      case vni_set
      when :enabled
        if /N9K/.match(node.product_id)
          config_set('vni', 'feature_n9k', state: '')
        else
          config_set('vni', 'feature', '')
        end
      when :disabled
        if /N9K/.match(node.product_id)
          # feature nv overlay is a dependency for disabling
          # feature vn-segment-vlan-based. Disable it first.
          if config_get('vni', 'feature_nv_overlay')
            config_set('vni', 'feature_nv_overlay', state: 'no')
            # Disabling feature nv overlay takes about 7-8 seconds.
            # Sleep for the time.
            sleep(8)
          end
          config_set('vni', 'feature_n9k', state: 'no') if curr == :enabled
        else
          config_set('vni', 'feature', 'no') if curr == :enabled
        end
        return
      end
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def create
      feature_set(:enabled) unless :enabled == feature
      return if /N9K/.match(node.product_id)
      config_set('vni', 'create', @vni_id)
    end

    def destroy
      if /N9K/.match(node.product_id)
        # Just destroy the vni-vlan mapping
        vlan = mapped_vlan
        config_set('vni', 'mapped_vlan', vlan: vlan, state: 'no', vni: @vni_id)
      else
        config_set('vni', 'destroy', @vni_id)
      end
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

    def encap_dot1q=(val, prev_val=nil)
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
      bd_arr = config_get('vni', 'bridge_domain', @vni_id)
      bd_arr.first.to_i
    end

    def bridge_domain=(val)
      no_cmd = (val) ? '' : 'no'
      config_set('vni', 'bridge_domain_activate', no_cmd, val)
      config_set('vni', 'bridge_domain', val, no_cmd, @vni_id)
    end

    def default_bridge_domain
      config_get_default('vni', 'bridge_domain')
    end

    def shutdown
      result = config_get('vni', 'shutdown', @vni_id)
      return default_shutdown if result.nil?
      # valid result is either: "active"(aka no shutdown) or "shutdown"
      result.first[/shut/] ? true : false
    end

    def mapped_vlan
      vlans = config_get('vlan', 'all_vlans')
      return nil if vlans.nil?
      vlans.each do |vlan|
        return vlan.to_i if
              config_get('vni', 'mapped_vlan', vlan: vlan) == @vni_id
      end
      nil
    end

    def mapped_vlan=(vlan)
      if vlan == default_mapped_vlan
        state = 'no'
        vlan = mapped_vlan
      else
        state = ''
      end
      # Nothing to be done if vlan is nil
      result = config_set('vni', 'mapped_vlan', vlan: vlan,
                 state: state, vni: @vni_id) unless vlan.nil?
      cli_error_check(result)
    rescue CliError => e
      raise "[vni #{@vni_id}] '#{e.command}' : #{e.clierror}"
    end

    def default_mapped_vlan
      config_get_default('vni', 'mapped_vlan')
    end

    def shutdown=(val)
      no_cmd = (val) ? '' : 'no'
      result = config_set('vni', 'shutdown', @vni_id, no_cmd)
      cli_error_check(result)
    rescue CliError => e
      raise "[vni #{@vni_id}] '#{e.command}' : #{e.clierror}"
    end

    def default_shutdown
      config_get_default('vni', 'shutdown')
    end
  end # class
end # module
