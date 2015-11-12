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
  class RouterAce < NodeUtil
    attr_reader :acl_name, :seqno, :action, :proto, :v4_src_addr_format, :v4_dst_addr_format
    attr_reader :v4_src_port_format, :v4_dst_port_format, :option_format

    # name: name of the router instance
    # instantiate: true = create router instance
    def initialize(acl_name, seqno, action, proto, v4_src_addr_format,
                   v4_dst_addr_format, v4_src_port_format, v4_dst_port_format,
                   option_format="", instantiate=true)
      addr_regex = /(any|host \d+\.\d+\.\d+\.\d+|\d+\.\d+\.\d+\.\d+\/\d+|\d+\.\d+\.\d+\.\d+ \d+\.\d+\.\d+\.\d+)/
      addr_port_regex = /((eq|neq|lt|gt)\s+\d+|range\s+\d+\s+\d+){0,1}/
      action_regex = /(permit|deny)/
      proto_regex = /(sctp|tcp|ip|udp|pim|icmp|igmp|gre|nos|pcp|ospf|eigrp|ahp|esp|ipv6)/
      fail ArgumentError.new("acl name len must be greater than 0") unless acl_name.length > 0
      fail ArgumentError.new("seqno must be an integer") unless seqno.is_a?(Integer)
      fail ArgumentError.new("action has to be permit or deny") unless action_regex.match(action)
      fail ArgumentError.new("proto is invalid") unless proto_regex.match(proto)
      fail ArgumentError.new("invalid src addr #{v4_src_addr_format}") unless addr_regex.match(v4_src_addr_format)
      fail ArgumentError.new("invalid dst addr") unless addr_regex.match(v4_dst_addr_format)
      fail ArgumentError.new("invalid src port") unless addr_port_regex.match(v4_src_port_format)
      fail ArgumentError.new("invalid dst port") unless addr_port_regex.match(v4_dst_port_format)

      @acl_name = acl_name
      @seqno    = seqno
      @action   = action
      @proto    = proto
      @v4_src_addr_format = v4_src_addr_format
      @v4_dst_addr_format = v4_dst_addr_format
      @v4_src_port_format = v4_src_port_format
      @v4_dst_port_format = v4_dst_port_format
      @option_format      = option_format
      @set_args = {} 
      @get_args = {} 
      create if instantiate
    end

    # Create a hash of all current router instances.
    def self.l3_aces
      instances = config_get('ace_v4' , 'l3_ace')
      return {} if instances.nil?
      hash = {}
      instances.each do |name|
        hash[name] = RouterAce.new(acl_name, false)
      end
      return hash
    rescue Cisco::CliError => e
      # CLI will syntax reject when feature is not enabled
      raise unless e.clierror =~ /Syntax error/
      return {}
    end
    
    # Create a hash of all current router instances.
    def self.l4_aces
      instances = config_get('ace_v4' , 'l4_ace')
      return {} if instances.nil?
      hash = {}
      instances.each do |name|
        hash[name] = RouterAce.new(acl_name, false)
      end
      return hash
    rescue Cisco::CliError => e
      # CLI will syntax reject when feature is not enabled
      raise unless e.clierror =~ /Syntax error/
      return {}
    end

    def is_l4_ace?
        "tcp|udp|sctp".match(@proto) ? true : false
    end

    # config ip access-list and create router instance
    def create
        config_l4_ace if is_l4_ace?
        config_l3_ace if !is_l4_ace?
    end
    
    # Destroy a router instance; disable feature on last instance
    def destroy
      ids = config_get('ace_v4', 'l3_ace')
      return if ids.nil?
      ids = config_get('ace_v4', 'l4_ace')
      return if ids.nil?
      config_l4_ace('no')
      config_l3_ace('no')
    rescue Cisco::CliError => e
      # CLI will syntax reject when feature is not enabled
      raise unless e.clierror =~ /Syntax error/
    end

    def config_l4_ace(state='')
      @set_args_acl = {}
      @set_args_acl[:acl_name] = @acl_name
      config_set('acl_v4', 'acl', @set_args_acl)
      @set_args[:seqno] = @seqno
      @set_args[:action] = @action
      @set_args[:state] = state
      @set_args[:proto] = @proto
      @set_args[:v4_src_addr_format] = @v4_src_addr_format
      @set_args[:v4_dst_addr_format] = @v4_dst_addr_format
      @set_args[:v4_src_port_format] = @v4_src_port_format
      @set_args[:v4_dst_port_format] = @v4_dst_port_format
      @set_args[:option_format] = @option_format
      config_set('ace_v4', 'l4_ace', @set_args)
    end
    
    def config_l3_ace(state='')
      #@set_args[:acl_name] = @acl_name
      @set_args[:seqno] = @seqno
      @set_args[:state] = state
      @set_args[:proto] = @proto
      @set_args[:action] = @action
      @set_args[:v4_src_addr_format] = @v4_src_addr_format
      @set_args[:v4_dst_addr_format] = @v4_dst_addr_format
      @set_args[:option_format] = @option_format
      config_set('ace_v4', 'l3_ace', @set_args)
    end


    # ----------
    # PROPERTIES
    # ----------
  end
end
