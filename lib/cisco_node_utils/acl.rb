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
      fail TypeError unless acl_name.is_a?(String)
      fail ArgumentError 'Argument afi must be ip or ipv6' unless
        afi == 'ip' || afi == 'ipv6'
      @set_args = @get_args = { acl_name: acl_name, afi: afi }
      create if instantiate
    end

    # it will return all acls in the switch
    def self.acls
      afis = %w(ip ipv6)
      acl_hash = {}
      afis.each do |afi|
        acl_hash[afi] = {}
        get_args = { afi: afi }
        instances = config_get('acl', 'all_acl', get_args)

        next if instances.nil?

        instances.each do |name|
          acl_hash[afi][name] = Acl.new(name, afi, false)
        end
      end
      acl_hash
    end

    # config ip access-list and create
    def create
      config_acl('')
    end

    # Destroy acl instance
    def destroy
      config_acl('no')
    end

    def config_acl(state)
      @set_args[:state] = state
      config_set('acl', 'acl', @set_args)
    end

    # ----------
    # PROPERTIES
    # ----------
    def stats_per_entry
      config_get('acl', 'stats_per_entry', @get_args)
    end

    def stats_per_entry=(state)
      @set_args[:state] = (state ? '' : 'no')
      config_set('acl', 'stats_per_entry', @set_args)
    end

    def default_stats_per_entry
      config_get_default('acl', 'stats_per_entry')
    end

    def fragments
      config_get('acl', 'fragments', @get_args)
    end

    def fragments=(permit)
      @set_args[:state] = (permit ? '' : 'no')
      if permit
        @set_args[:permit] = permit
        config_set('acl', 'fragments', @set_args)
      else
        @set_args[:permit] = 'permit-all'
        config_set('acl', 'fragments', @set_args)
        @set_args[:permit] = 'deny-all'
        config_set('acl', 'fragments', @set_args)
      end
    end

    def default_fragments
      config_get_default('acl', 'fragments')
    end

    # acl == overide func
    def ==(other)
      acl_name == other.acl_name && afi == other.afi
    end
  end
end
