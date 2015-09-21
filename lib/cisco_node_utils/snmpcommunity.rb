# December 2014, Alex Hunsberger
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

require File.join(File.dirname(__FILE__), 'node_util')

module Cisco
  # SnmpCommunity - node utility class for SNMP community config management
  class SnmpCommunity < NodeUtil
    @communities = nil

    def initialize(name, group, instantiate=true)
      fail TypeError unless name.is_a?(String) && group.is_a?(String)
      @name = name
      return unless instantiate
      config_set('snmp_community', 'community', '', name, group)
    end

    def self.communities
      @communities = {}
      comms = config_get('snmp_community', 'all_communities')
      unless comms.nil?
        comms.each do |comm|
          @communities[comm] = SnmpCommunity.new(comm, '', false)
        end
      end
      @communities
    end

    def destroy
      # CLI requires specifying a group even for "no" commands
      config_set('snmp_community', 'community', 'no', @name, 'null')
      @communities.delete(@name) unless @communities.nil?
    end

    # name is read only
    #  def name
    #    @name
    #  end

    def group
      result = config_get('snmp_community', 'group', @name)
      result.nil? ? SnmpCommunity.default_group : result.first
    end

    def group=(group)
      fail TypeError unless group.is_a?(String)
      config_set('snmp_community', 'group', @name, group)
    end

    def self.default_group
      config_get_default('snmp_community', 'group')
    end

    def acl
      result = config_get('snmp_community', 'acl', @name)
      result.nil? ? SnmpCommunity.default_acl : result.first
    end

    def acl=(acl)
      fail TypeError unless acl.is_a?(String)
      if acl.empty?
        acl = self.acl
        config_set('snmp_community', 'acl', 'no', @name, acl) unless acl.empty?
      else
        config_set('snmp_community', 'acl', '', @name, acl)
      end
    end

    def self.default_acl
      config_get_default('snmp_community', 'acl')
    end
  end
end
