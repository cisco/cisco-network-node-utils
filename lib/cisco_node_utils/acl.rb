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
  # Acl - node utility class for ACL configuration
  class Acl < NodeUtil
    attr_reader :acl_name, :afi

    # acl_name: name of the acl
    # instantiate: true = create acl instance
    def initialize(acl_name, afi, instantiate=true)
      @acl_name = acl_name
      @afi = afi
      @set_args = @get_args = { acl_name: @acl_name, afi: @afi }
      create if instantiate
    end

    # it will return all acls in the switch
    def self.acls
      afis = %w(ip ipv6)
      afis.each do |afi|
        @get_args = { afi: afi }
        instances = config_get('acl', 'all_acl', @get_args)
        return {} if instances.nil?
        hash = {}
        instances.each do |name|
          hash[name] = Acl.new(name, @get_args[:afi], false)
        end
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
      config_set('acl', 'acl', @set_args)
    end

    # ----------
    # PROPERTIES
    # ----------
    # getter acl info
    def acl
      config_get('acl', 'acl', @get_args)
    end

    # setter acl info
    def acl=(state)
      @set_args[:state] = (state ? '' : 'no')
      config_set('acl', 'acl', @set_args)
    end

    # getter stats perentry info
    def stats_perentry
      config_get('acl', 'stats_perentry', @get_args)
    end

    # setter stats perentry info
    def stats_perentry=(state)
      @set_args[:state] = (state ? '' : 'no')
      config_set('acl', 'stats_perentry', @set_args)
    end
  end
end
