# December 2014, Alex Hunsberger
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
  # SnmpCommunity - node utility class for SNMP community config management
  class SnmpCommunity < NodeUtil
    @communities = nil

    def initialize(name, group, instantiate=true)
      fail TypeError unless name.is_a?(String)
      fail TypeError unless group.is_a?(String)
      @name = name
      return unless instantiate
      if platform == :nexus
        config_set('snmp_community', 'community',
                   state: '',
                   name:  @name,
                   group: group)
      else
        config_set('snmp_community', 'community',
                   state: '',
                   name:  @name)
        # create the mapping for group
        config_set('snmp_community', 'group_simple', state: '', group: group)
        config_set('snmp_community', 'group_community_mapping', name: @name, group: group) # rubocop:disable Metrics/LineLength
      end
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
      config_set('snmp_community', 'community',
                 state: 'no',
                 name:  @name,
                 group: 'null')
    end

    # name is read only
    #  def name
    #    @name
    #  end

    def group
      if platform == :nexus
        config_get('snmp_community', 'group', name: @name)
      else
        config_get('snmp_community', 'group_community_mapping', name: @name)
      end
    end

    def group=(group)
      fail TypeError unless group.is_a?(String)
      if platform == :nexus
        config_set('snmp_community', 'group', name: @name, group: group)
      else
        # create the mapping
        config_set('snmp_community', 'group_simple', group: group)
        config_set('snmp_community', 'group_community_mapping', name: @name, group: group) # rubocop:disable Metrics/LineLength
      end
    end

    def self.default_group
      config_get_default('snmp_community', 'group')
    end

    def acl
      config_get('snmp_community', 'acl', name: @name)
    end

    def acl=(acl)
      fail TypeError unless acl.is_a?(String)
      if acl.empty?
        acl = self.acl
        config_set('snmp_community', 'acl', state: 'no', name: @name, acl: acl) unless acl.empty? # rubocop:disable Metrics/LineLength
      else
        config_set('snmp_community', 'acl', state: '', name: @name, acl: acl)
      end
    end

    def self.default_acl
      config_get_default('snmp_community', 'acl')
    end
  end
end
