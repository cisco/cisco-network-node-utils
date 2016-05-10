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

    # Create one router ospf instance
    def create
      Feature.ospf_enable
      config_set('ospf', 'router', state: '', name: @name)
      wait_for_process_initialized
    end

    # Destroy one router ospf instance
    def destroy
      config_set('ospf', 'router', state: 'no', name: @name)
    end

    def process_initialized?
      !config_get('ospf', 'process_initialized')
    end

    def wait_for_process_initialized
      return unless node.product_id[/N(5|6|8)/]

      # Hack for slow-start platforms which will have setter failures if the
      # ospf instance is still initializing. To see this problem in a sandbox
      # or even the cli do 'router ospf 1 ; router ospf 1 ; shutdown'.
      4.times do
        return if process_initialized?
        sleep 1
        node.cache_flush
      end
      fail 'OSPF process is not initialized yet'
    end
  end
end
