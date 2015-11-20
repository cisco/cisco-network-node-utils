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
  class Ace < NodeUtil
    attr_reader :acl_name, :seqno, :afi

    # name: name of the router instance
    # instantiate: true = create router instance
    def initialize(acl_name, seqno, afi)
      @acl_name = acl_name
      @afi = afi
      @seqno = seqno
      @set_args = @get_args = { acl_name: @acl_name, seqno: @seqno }
    end

    # Create a hash of all current router instances.
    def self.aces
      instances = config_get('acl_v4', 'ace')
      return {} if instances.nil?
      hash = {}
      instances.each do |name|
        hash[name] = Ace.new(acl_name, false)
      end
      return hash
    rescue Cisco::CliError => e
      # CLI will syntax reject when feature is not enabled
      raise unless e.clierror =~ /Syntax error/
      return {}
    end

    # Destroy a router instance; disable feature on last instance
    def destroy
      config_ace('no')
    rescue Cisco::CliError => e
      # CLI will syntax reject when feature is not enabled
      raise unless e.clierror =~ /Syntax error/
    end

    # First create acl
    def config_ace(state='')
      @set_args[:state] = state
      config_set('acl_v4', 'ace', @set_args)
    end

    # ----------
    # PROPERTIES
    # ----------
    # getter of seqno
    def seqno
      match = config_get('acl_v4', 'ace', @get_args)
      return if match.nil?
      match[0]
    end

    # setter of seqno
    def seqno=(state)
      @set_args[:state] = state ? '' : 'no'
    end

    # getter of action
    def action
      match = config_get('acl_v4', 'ace', @get_args)
      return if match.nil?
      match[1]
    end

    # setter of action
    def action=(action)
      @set_args[:action] = action
    end

    # getter of proto
    def proto
      match = config_get('acl_v4', 'ace', @get_args)
      return if match.nil?
      match[2]
    end

    # setter of proto
    def proto=(proto)
      @set_args[:proto] = proto
    end

    # getter of v4_src_addr_format
    def v4_src_addr_format
      match = config_get('acl_v4', 'ace', @get_args)
      return if match.nil?
      match[3]
    end

    # setter of v4_src_addr_format
    def v4_src_addr_format=(src_addr)
      @set_args[:v4_src_addr_format] = src_addr
    end

    # getter of v4_src_port_format
    def v4_src_port_format
      match = config_get('acl_v4', 'ace', @get_args)
      return if match.nil?
      match[5]
    end

    # setter of v4_src_port_format
    def v4_src_port_format=(src_port)
      @set_args[:v4_src_port_format] = src_port
    end

    # getter of v4_dst_addr_format
    def v4_dst_addr_format
      match = config_get('acl_v4', 'ace', @get_args)
      return if match.nil?
      match[6]
    end

    # setter of v4_dst_addr_format
    def v4_dst_addr_format=(dst_addr)
      @set_args[:v4_dst_addr_format] = dst_addr
    end

    # getter of v4_dst_port_format
    def v4_dst_port_format
      match = config_get('acl_v4', 'ace', @get_args)
      return if match.nil?
      match[7]
    end

    # setter of v4_dst_port_format
    def v4_dst_port_format=(src_port)
      @set_args[:v4_dst_port_format] = src_port
    end

    # getter of option_format
    def option_format
      match = config_get('acl_v4', 'ace', @get_args)
      return if match.nil?
      match[8]
    end

    # setter of option_format
    def option_format=(option)
      @set_args[:option_format] = option
    end
  end
end
