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
  # Acl - node utility class for ACL configuration
  class Acl < NodeUtil
    attr_reader :acl_name, :afi

    def initialize(afi, acl_name, instantiate=true)
      @set_args = @get_args = { afi: Acl.afi_cli(afi), acl_name: acl_name.to_s }
      create if instantiate
    end

    # Return all acls currently on the switch
    def self.acls
      afis = %w(ipv4 ipv6)
      acl_hash = {}
      afis.each do |afi|
        acl_hash[afi] = {}
        afi_cli = Acl.afi_cli(afi)
        instances = config_get('acl', 'all_acls', afi: afi_cli)

        next if instances.nil?
        instances.each do |acl_name|
          acl_hash[afi][acl_name] = Acl.new(afi, acl_name, false)
        end
      end
      acl_hash
    end

    # Platform-specific afi cli string
    def self.afi_cli(afi)
      fail ArgumentError, "Argument afi must be 'ipv4' or 'ipv6'" unless
        afi[/(ipv4|ipv6)/]
      afi[/ipv4/] ? 'ip' : afi
    end

    def create
      config_acl('')
    end

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

    def fragments=(action)
      @set_args[:state] = (action ? '' : 'no')
      action = fragments unless action
      @set_args[:action] = action
      config_set('acl', 'fragments', @set_args) if action
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
