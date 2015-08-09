# VLAN provider class
#
# Jie Yang, November 2014
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

require File.join(File.dirname(__FILE__), 'node')
require File.join(File.dirname(__FILE__), 'interface')

module Cisco
  VLAN_NAME_SIZE = 33

  class Vlan
    attr_reader :name, :vlan_id

    @@node = Node.instance
    raise TypeError if @@node.nil?

    def initialize(vlan_id, instantiate=true)
      @vlan_id = vlan_id.to_s
      raise ArgumentError,
        "Invalid value(non-numeric Vlan id)" unless @vlan_id[/^\d+$/]

      create if instantiate
    end

    def Vlan.vlans
      hash = {}
      vlan_list = @@node.config_get("vlan", "all_vlans")
      return hash if vlan_list.nil?

      vlan_list.each do |id|
        hash[id] = Vlan.new(id, false)
      end
      hash
    end

    def create
      @@node.config_set("vlan", "create", @vlan_id)
    end

    def destroy
      @@node.config_set("vlan", "destroy", @vlan_id)
    end

    def cli_error_check(result)
      # The NXOS vlan cli does not raise an exception in some conditions and
      # instead just displays a STDOUT error message; thus NXAPI does not detect
      # the failure and we must catch it by inspecting the "body" hash entry
      # returned by NXAPI. This vlan cli behavior is unlikely to change.
      raise result[2]["body"] unless result[2]["body"].empty?
    end

    def vlan_name
      result = @@node.config_get("vlan", "name", @vlan_id)
      return default_vlan_name if result.nil?
      result.shift
    end

    def vlan_name=(str)
      raise TypeError unless str.is_a?(String)
      if str.empty?
        result = @@node.config_set("vlan", "name", @vlan_id, "no", "")
      else
        result = @@node.config_set("vlan", "name", @vlan_id, "", str)
      end
      cli_error_check(result)
    rescue CliError => e
      raise "[vlan #{@vlan_id}] '#{e.command}' : #{e.clierror}"
    end

    def default_vlan_name
      "VLAN%04d" % @vlan_id
    end

    def state
      result = @@node.config_get("vlan", "state", @vlan_id)
      return default_state if result.nil?
      case result.first
      when /act/
        return "active"
      when /sus/
        return "suspend"
      end
    end

    def state=(str)
      str = str.to_s
      if str.empty?
        result = @@node.config_set("vlan", "state", @vlan_id, "no", "")
      else
        result = @@node.config_set("vlan", "state", @vlan_id, "", str)
      end
      cli_error_check(result)
    rescue CliError => e
      raise "[vlan #{@vlan_id}] '#{e.command}' : #{e.clierror}"
    end

    def default_state
      @@node.config_get_default("vlan", "state")
    end

    def shutdown
      result = @@node.config_get("vlan", "shutdown", @vlan_id)
      return default_shutdown if result.nil?
      # valid result is either: "active"(aka no shutdown) or "shutdown"
      result.first[/shut/] ? true : false
    end

    def shutdown=(val)
      no_cmd = (val) ? "" : "no"
      result = @@node.config_set("vlan", "shutdown", @vlan_id, no_cmd)
      cli_error_check(result)
    rescue CliError => e
      raise "[vlan #{@vlan_id}] '#{e.command}' : #{e.clierror}"
    end

    def default_shutdown
      @@node.config_get_default("vlan", "shutdown")
    end

    def add_interface(interface)
      interface.access_vlan = @vlan_id
    end

    def remove_interface(interface)
      interface.access_vlan = interface.default_access_vlan
    end

    def interfaces
      all_interfaces = Interface.interfaces
      interfaces = {}
      all_interfaces.each do |name, i|
        next unless i.switchport_mode == :access
        next unless i.access_vlan == @vlan_id
        interfaces[name] = i
      end
      interfaces
    end
  end # class
end # module
