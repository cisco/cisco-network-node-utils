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
  class Acl < NodeUtil
    attr_reader :acl_name, :afi

    # name: name of the router instance
    # instantiate: true = create router instance
    def initialize(acl_name, afi, instantiate=true)
      @acl_name = acl_name
      @afi = afi
      @set_args = @get_args = {acl_name: @acl_name} 
      create if instantiate
    end

    def self.acls
      instances = config_get('acl_v4' , 'acl') if @afi == "v4"
      instances = config_get('acl_v6' , 'acl') if @afi == "v6"
      return {} if instances.nil?
      hash = {}
      instances.each do |name|
        hash[name] = Acl.new(acl_name, false)
      end
      return hash
    rescue Cisco::CliError => e
      # CLI will syntax reject when feature is not enabled
      raise unless e.clierror =~ /Syntax error/
      return {}
    end

    # config ip access-list and create
    def create
        config_acl('')
    end

    # Destroy a router instance; disable feature on last instance
    def destroy
      config_acl('no')
    rescue Cisco::CliError => e
      # CLI will syntax reject when feature is not enabled
      raise unless e.clierror =~ /Syntax error/
    end

    def config_acl(state)
      @set_args[:state] = state
      config_set('acl_v4', 'acl', @set_args) if @afi == "v4"
      config_set('acl_v6', 'acl', @set_args) if @afi == "v6"
    end

    # ----------
    # PROPERTIES
    # ----------
    # getter acl info
    def acl
      config_get('acl_v4', 'acl', @get_args) if @afi == "v4"
      config_get('acl_v6', 'acl', @get_args) if @afi == "v6"
    end
    # setter acl info
    def acl=(state)
      @set_args[:state] = (state ? '' : 'no') 
      config_set('acl_v4', 'acl', @set_args) if @afi == "v4"
      config_set('acl_v6', 'acl', @set_args) if @afi == "v6"
    end

    # getter stats perentry info
    def stats_perentry
      config_get('acl_v4', 'stats_perentry', @get_args) if @afi == "v4"
      config_get('acl_v6', 'stats_perentry', @get_args) if @afi == "v6"
    end

    # setter stats perentry info
    def stats_perentry=(state)
      @set_args[:state] = (state ? '' : 'no') 
      config_set('acl_v4', 'stats_perentry', @set_args) if @afi == "v4"
      config_set('acl_v6', 'stats_perentry', @set_args) if @afi == "v6"
    end
  end
end
