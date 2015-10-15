# Domain Name provider class
#
# October 2015, Bryan Jen
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
  # DomainName- node utility class for domain name configuration
  class DomainName < NodeUtil
    attr_reader :name, :vrf

    def initialize(name, vrf=nil, instantiate=true)
      @name = name
      @vrf = vrf
      create if instantiate
    end

    def self.domainnames(vrf=nil)
      hash = {}
      if vrf.nil?
        domains = config_get('dnsclient', 'domain_name')
      else
        domains = config_get('dnsclient', 'domain_name_vrf', vrf: vrf)
      end
      return hash if domains.nil?

      domains.each do |name|
        hash[name] = DomainName.new(name, vrf, false)
      end
      hash
    end

    def ==(other)
      (name == other.name) && (vrf == other.vrf)
    end

    def create
      if @vrf.nil?
        config_set('dnsclient', 'domain_name',
                   state: '', name: @name)
      else
        config_set('dnsclient', 'domain_name_vrf',
                   state: '', name: @name, vrf: @vrf)
      end
    end

    def destroy
      if @vrf.nil?
        config_set('dnsclient', 'domain_name',
                   state: 'no', name: @name)
      else
        config_set('dnsclient', 'domain_name_vrf',
                   state: 'no', name: @name, vrf: @vrf)
      end
    end
  end
end
