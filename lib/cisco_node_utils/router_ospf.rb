# November 2014, Chris Van Heuveln
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

require_relative 'node_util'

module Cisco
  # RouterOspf - node utility class for process-level OSPF config management
  class RouterOspf < NodeUtil
    attr_reader :name

    def initialize(name, instantiate=true)
      fail ArgumentError unless name.length > 0
      @name = name

      create if instantiate
    end

    # Create a hash of all router ospf instances
    def self.routers
      ospf_ids = config_get('ospf', 'router')
      return {} if ospf_ids.nil?

      hash = {}
      ospf_ids.each do |name|
        hash[name] = RouterOspf.new(name, false)
      end
      return hash
    rescue Cisco::CliError => e
      # cmd will syntax reject when feature is not enabled
      raise unless e.clierror =~ /Syntax error/
      return {}
    end

    def self.enabled
      feat = config_get('ospf', 'feature')
      return (!feat.nil? && !feat.empty?)
    rescue Cisco::CliError => e
      # cmd will syntax reject when feature is not enabled
      raise unless e.clierror =~ /Syntax error/
      return false
    end

    def self.enable(state='')
      config_set('ospf', 'feature', state)
    end

    def ospf_router(name, state='')
      config_set('ospf', 'router', state, name)
    end

    def enable_create_router_ospf(name)
      RouterOspf.enable
      ospf_router(name)
    end

    # Create one router ospf instance
    def create
      if RouterOspf.enabled
        ospf_router(name)
      else
        enable_create_router_ospf(name)
      end
    end

    # Destroy one router ospf instance
    def destroy
      ospf_ids = config_get('ospf', 'router')
      return if ospf_ids.nil?
      if ospf_ids.size == 1
        RouterOspf.enable('no')
      else
        ospf_router(name, 'no')
      end
    rescue Cisco::CliError => e
      # cmd will syntax reject when feature is not enabled
      raise unless e.clierror =~ /Syntax error/
    end
  end
end
