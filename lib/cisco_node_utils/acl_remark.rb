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
  class Remark < NodeUtil
    attr_reader :afi, :acl_name, :seqno

    # name: name of the router instance
    # instantiate: true = create router instance
    def initialize(afi, acl_name, seqno)
      fail TypeError unless
        acl_name.is_a?(String) && seqno.is_a?(Integer) && afi.is_a?(String)
      fail ArgumentError 'we expect ip or ipv6' unless
        afi == 'ip' || afi == 'ipv6'
      @acl_name = acl_name
      @afi = afi
      @seqno = seqno
      @set_args = @get_args = { acl_name: @acl_name, seqno: @seqno, afi: @afi }
    end

    # Create a hash of all current router instances.
    def self.aces
      instances = config_get('acl', 'remark')
      return {} if instances.nil?
      hash = {}
      instances.each do |name|
        hash[name] = Remark.new(acl_name, false)
      end
      return hash
    rescue Cisco::CliError => e
      # CLI will syntax reject when feature is not enabled
      raise unless e.clierror =~ /Syntax error/
      return {}
    end

    # Destroy a router instance; disable feature on last instance
    def destroy
      config_remark('no')
    rescue Cisco::CliError => e
      # CLI will syntax reject when feature is not enabled
      raise unless e.clierror =~ /Syntax error/
    end

    # First create acl
    def config_remark(state='')
      @set_args[:state] = state
      config_set('acl', 'remark', @set_args)
    end

    # ----------
    # PROPERTIES
    # ----------
    # getter of seqno
    def seqno
      match = config_get('acl', 'remark', @get_args)
      return if match.nil?
      match[0]
    end

    # setter of seqno
    def seqno=(state)
      @set_args[:state] = state ? '' : 'no'
    end

    # getter of remark 
    def remark_str 
      match = config_get('acl', 'remark', @get_args)
      return if match.nil?
      match[2]
    end

    # setter of remark 
    def remark_str=(remark_str)
      puts remark_str
      @set_args[:remark_str] = remark_str
      return remark_str 
    end

  end
end
