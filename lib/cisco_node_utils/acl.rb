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

require_relative 'node_util'

module Cisco
  # RouterAcl - node utility class for RouterAcl config mgmt.
  class RouterAcl < NodeUtil
    attr_reader :acl_name, :afi

    # name: name of the router instance
    # instantiate: true = create router instance
    def initialize(acl_name, afi, instantiate=true)
      fail ArgumentError unless acl_name.length > 0
      @acl_name = acl_name
      @afi = afi
      @set_args = {} 
      @get_args = {} 
      create if instantiate
    end

    # Create a hash of all current router instances.
    def self.routers
      instances = config_get('acl_v4' , 'acl') if @afi == "v4"
      instances = config_get('acl_v6' , 'acl') if @afi == "v6"
      return {} if instances.nil?
      hash = {}
      instances.each do |name|
        hash[name] = RouterAcl.new(acl_name, false)
      end
      return hash
    rescue Cisco::CliError => e
      # CLI will syntax reject when feature is not enabled
      raise unless e.clierror =~ /Syntax error/
      return {}
    end

    # config ip access-list and create router instance
    def create
        config_ip_acl
    end

    # Destroy a router instance; disable feature on last instance
    def destroy
      config_ip_acl('no')
    rescue Cisco::CliError => e
      # CLI will syntax reject when feature is not enabled
      raise unless e.clierror =~ /Syntax error/
    end

    def config_ip_acl(state='')
      @set_args[:acl_name] = @acl_name.to_s
      @set_args[:state] = state
      config_set('acl_v4', 'acl', @set_args) if @afi == "v4"
      config_set('acl_v6', 'acl', @set_args) if @afi == "v6"
    end

    def config_stats_enable
        @set_args[":state"] = ""
        config_set('acl_v4', 'stats_perentry', @set_args) if @afi == "v4"
        config_set('acl_v6', 'stats_perentry', @set_args) if @afi == "v6"
    end
    
    def stats_disable
        @set_args[":state"] = "no"
        config_set('acl_v4', 'stats_perentry', @set_args) if @afi == "v4"
        config_set('acl_v6', 'stats_perentry', @set_args) if @afi == "v6"
    end

    def stats_enabled
        stats = config_get('acl_v4', 'stats_perentry') if @afi == "v4"
        return !(stats.nil? || stats.empty?) if @afi == "v4"
        stats = config_get('acl_v6', 'stats_perentry') if @afi == "v6"
        return !(stats.nil? || stats.empty?) if @afi == "v6"
    end

    # ----------
    # PROPERTIES
    # ----------

    # Property methods for boolean property
  end
end
