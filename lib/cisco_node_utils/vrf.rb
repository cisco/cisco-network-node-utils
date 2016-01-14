# VRF provider class
#
# Jie Yang, July 2015
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
require_relative 'vni'

module Cisco
  # Vrf - node utility class for VRF configuration management
  class Vrf < NodeUtil
    attr_reader :name

    def initialize(name, instantiate=true)
      fail TypeError unless name.is_a?(String)
      @name = name.downcase.strip
      @args = { vrf: @name }
      create if instantiate
    end

    def self.vrfs
      hash = {}
      vrf_list = config_get('vrf', 'all_vrfs')
      return hash if vrf_list.nil?

      vrf_list.each do |id|
        id = id.downcase.strip
        hash[id] = Vrf.new(id, false)
      end
      hash
    end

    def create
      config_set('vrf', 'create', @args)
    end

    def destroy
      config_set('vrf', 'destroy', @args)
    end

    def description
      config_get('vrf', 'description', @args)
    end

    def description=(desc)
      fail TypeError unless desc.is_a?(String)
      desc.strip!
      no_cmd = desc.empty? ? 'no' : ''
      config_set('vrf', 'description', vrf: @name, state: no_cmd, desc: desc)
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def shutdown
      config_get('vrf', 'shutdown', @args)
    end

    def shutdown=(val)
      no_cmd = (val) ? '' : 'no'
      config_set('vrf', 'shutdown', vrf: @name, state: no_cmd)
    rescue Cisco::CliError => e
      raise "[vrf #{@name}] '#{e.command}' : #{e.clierror}"
    end

    def self.feature_vn_segment_vlan_based_enabled
      config_get('vrf', 'feature_vn_segment_vlan_based')
    rescue Cisco::CliError => e
      # cmd will syntax reject when feature is not enabled
      raise unless e.clierror =~ /Syntax error/
      return false
    end

    def self.feature_vn_segment_vlan_based_enable
      config_set('vrf', 'feature_vn_segment_vlan_based')
    end

    # Vni (Getter/Setter/Default)
    def vni
      config_get('vrf', 'vni', @args)
    end

    def vni=(id)
      Vrf.feature_vn_segment_vlan_based_enable unless
        Vrf.feature_vn_segment_vlan_based_enabled
      no_cmd = (id) ? '' : 'no'
      id = (id) ? id : vni
      config_set('vrf', 'vni', vrf: @name, state: no_cmd, id: id)
    rescue Cisco::CliError => e
      raise "[vrf #{@name}] '#{e.command}' : #{e.clierror}"
    end

    def default_vni
      config_get_default('vrf', 'vni')
    end
  end # class
end # module
