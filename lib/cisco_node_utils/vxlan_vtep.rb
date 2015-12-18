#
# NXAPI implementation of VXLAN_VTEP class
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

require_relative 'node_util'

module Cisco
  # node_utils class for vxlan_vtep
  class VxlanVtep < NodeUtil
    attr_reader :name

    def initialize(name, instantiate=true)
      fail TypeError unless name.is_a?(String)
      fail ArgumentError unless name.length > 0
      @name = name.downcase

      create if instantiate
    end

    def self.vteps
      hash = {}
      return hash unless feature_enabled
      vtep_list = config_get('vxlan_vtep', 'all_interfaces')
      return hash if vtep_list.nil?

      vtep_list.each do |id|
        id = id.downcase
        hash[id] = VxlanVtep.new(id, false)
      end
      hash
    end

    def self.feature_enabled
      config_get('vxlan', 'feature')
    rescue Cisco::CliError => e
      # cmd will syntax when feature is not enabled.
      raise unless e.clierror =~ /Syntax error/
      return false
    end

    def self.enable(state='')
      # vdc only supported on n7k currently.
      vdc_name = config_get('limit_resource', 'vdc')
      config_set('limit_resource', 'vxlan', vdc_name) unless vdc_name.nil?
      config_set('vxlan', 'feature', state: state)
    end

    def create
      VxlanVtep.enable unless VxlanVtep.feature_enabled
      # re-use the "interface command ref hooks"
      config_set('interface', 'create', @name)
    end

    def destroy
      # re-use the "interface command ref hooks"
      config_set('interface', 'destroy', @name)
    end

    def ==(other)
      name == other.name
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    def description
      config_get('interface', 'description', @name)
    end

    def description=(desc)
      fail TypeError unless desc.is_a?(String)
      if desc.empty?
        config_set('interface', 'description', @name, 'no', '')
      else
        config_set('interface', 'description', @name, '', desc)
      end
    end

    def default_description
      config_get_default('interface', 'description')
    end

    def host_reachability
      hr = config_get('vxlan_vtep', 'host_reachability', name: @name)
      hr == 'bgp' ? 'evpn' : hr
    end

    def host_reachability=(val)
      set_args = { name: @name, proto: 'bgp' }
      if val.to_s == 'flood' && host_reachability == 'evpn'
        set_args[:state] = 'no'
      elsif val.to_s == 'evpn'
        set_args[:state] = ''
      end
      config_set('vxlan_vtep', 'host_reachability', set_args)
    end

    def default_host_reachability
      config_get_default('vxlan_vtep', 'host_reachability')
    end

    def source_interface
      config_get('vxlan_vtep', 'source_intf', name: @name)
    end

    def source_interface_set(val)
      set_args = { name: @name, lpbk_intf: val }
      val.empty? ? set_args[:state] = 'no' : set_args[:state] = ''
      config_set('vxlan_vtep', 'source_intf', set_args)
    end

    def source_interface=(val)
      # The source interface can only be changed if the nve
      # interface is in a shutdown state.
      current_state = shutdown
      self.shutdown = true unless shutdown
      source_interface_set(val)
      self.shutdown = current_state
    end

    def default_source_interface
      config_get_default('vxlan_vtep', 'source_intf')
    end

    def shutdown
      config_get('vxlan_vtep', 'shutdown', name: @name)
    end

    def shutdown=(bool)
      state = (bool ? '' : 'no')
      config_set('vxlan_vtep', 'shutdown', name: @name, state: state)
    end

    def default_shutdown
      config_get_default('vxlan_vtep', 'shutdown')
    end
  end  # Class
end    # Module
