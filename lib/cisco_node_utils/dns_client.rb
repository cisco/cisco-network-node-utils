#
# NXAPI implementation of DnsClient class
#
# September 2015, Hunter Haugen
#
# Copyright (c) 2015 Cisco and/or its affiliates.
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

require File.join(File.dirname(__FILE__), 'node')

module Cisco
  class DnsClient
    attr_reader :name

    @@node = Cisco::Node.instance

    def initialize(name, instantiate=true)
      fail TypeError unless name.is_a?(String)
      @name = name
      create if instantiate
    end

    def self.nameservers
      hosts = @@node.config_get('nameserver','all_nameservers')
      return {} if hosts.nil?

      hash = {}
      hosts.each do |name|
        hash[name] = name
        hash[name] = self.new(name, false)
      end
      hash
    end

    def create
      @@node.config_set('nameserver', 'create', @name)
    end

    def destroy
      @@node.config_set('nameserver', 'destroy', @name)
    end
  end
end
