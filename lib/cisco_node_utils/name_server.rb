#
# NXAPI implementation of NameServer class
#
# September 2015, Hunter Haugen
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
  # NameServer - node utility class for DNS client name server config management
  class NameServer < NodeUtil
    attr_reader :name

    def initialize(name, instantiate=true)
      unless name.is_a? String
        fail TypeError, "Expected a string, got a #{name.inspect}"
      end
      @name = name
      create if instantiate
    end

    def self.nameservers
      hosts = config_get('dnsclient', 'name_server')
      return {} if hosts.nil?

      hash = {}
      # Join and split because config_get returns array of strings separated by
      # spaces (regexes are a subset of PDA)
      hosts.join(' ').split(' ').each do |name|
        hash[name] = NameServer.new(name, false)
      end
      hash
    end

    def ==(other)
      name == other.name
    end

    def create
      config_set('dnsclient', 'name_server', state: '', ip: @name)
    end

    def destroy
      config_set('dnsclient', 'name_server', state: 'no', ip: @name)
    end
  end
end
