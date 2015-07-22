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

require File.join(File.dirname(__FILE__), 'node')

module Cisco
  class Vrf
    attr_reader :name

    @@node = Node.instance
    raise TypeError if @@node.nil?

    def initialize(name, instantiate=true)
      raise TypeError unless name.is_a?(String)
      @name = name.downcase.strip
      @args = { :vrf => @name }
      create if instantiate
    end

    def Vrf.vrfs
      hash = {}
      vrf_list = @@node.config_get("vrf", "all_vrfs")
      return hash if vrf_list.nil?

      vrf_list.each do |id|
        id = id.downcase.strip
        hash[id] = Vrf.new(id, false)
      end
      hash
    end

    def create
      @@node.config_set("vrf", "create", @args)
    end

    def destroy
      @@node.config_set("vrf", "destroy", @args)
    end

    def description
      desc = @@node.config_get("vrf", "description", @args)
      return "" if desc.nil?
      desc.shift.strip
    end

    def description=(desc)
      raise TypeError unless desc.is_a?(String)
      desc.strip!
      no_cmd = desc.empty? ? "no" : ""
      @@node.config_set("vrf", "description",
                        { :vrf=>@name, :state => no_cmd, :desc => desc })
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def shutdown
      result = @@node.config_get("vrf", "shutdown", @args)
      result ? true : false
    end

    def shutdown=(val)
      no_cmd = (val) ? "" : "no"
      @@node.config_set("vrf", "shutdown", { :vrf=> @name, :state => no_cmd })
    rescue Cisco::CliError => e
      raise "[vrf #{@name}] '#{e.command}' : #{e.clierror}"
    end
  end # class
end # module
