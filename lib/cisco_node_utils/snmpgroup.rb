#
# NXAPI implementation of SnmpGroup class
#
# February 2015, Chris Van Heuveln
#
# Copyright (c) 2015-2016 Cisco and/or its affiliates.
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
#
# "group" is a standard SNMP term but in NXOS "role" is used to serve the
# purpose of group; thus this provider utility does not create snmp groups
# and is limited to reporting group (role) existence only.

require_relative 'node_util'

module Cisco
  # SnmpGroup - node utility class for SNMP group configuration management
  class SnmpGroup < NodeUtil
    attr_reader :name

    def initialize(name)
      fail TypeError unless name.is_a?(String)
      @name = name
    end

    def self.groups
      group_ids = config_get('snmp_group', 'group')
      return {} if group_ids.nil?

      hash = {}
      group_ids.each do |name|
        hash[name] = SnmpGroup.new(name)
      end
      hash
    end

    def self.exists?(group)
      fail ArgumentError if group.empty?
      fail TypeError unless group.is_a? String
      groups = config_get('snmp_group', 'group')
      (!groups.nil? && groups.include?(group))
    end
  end
end
