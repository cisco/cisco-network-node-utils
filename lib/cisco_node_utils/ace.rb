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
  # Ace - node utility class for Ace Configuration
  class Ace < NodeUtil
    attr_reader :acl_name, :seqno, :afi, :set_args, :get_args
    attr_reader :regexp_str

    # acl_name is name of acl
    # seqno is sequence number of ace
    # afi is either v4 or v6
    def initialize(acl_name, seqno, afi)
      fail TypeError unless
        acl_name.is_a?(String) && seqno.is_a?(Integer) && afi.is_a?(String)
      fail ArgumentError 'we expect ip or ipv6' unless
        afi == 'ip' || afi == 'ipv6'
      @acl_name = acl_name
      @afi = afi
      @seqno = seqno
      @set_args = @get_args = { acl_name: @acl_name, seqno: @seqno, afi: @afi,
                                src_port: '', dst_port: '',
                                option_format: '' }
      @regexp_str = '(?<seqno>\d+) (?<action>\S+)'\
                 ' *(?<proto>\d+|\S+)'\
                 ' *(?<src_addr>any|host \S+|\S+\/\d+|\S+ [:\.0-9a-fA-F]+|'\
                 'addrgroup \S+)*'\
                 ' *(?<src_port>eq \S+|neq \S+|lt \S+|''gt \S+|range \S+ \S+|'\
                 'portgroup \S+)?'\
                 ' *(?<dst_addr>any|host \S+|\S+\/\d+|\S+ [:\.0-9a-fA-F]+|'\
                 'addrgroup \S+)'\
                 ' *(?<dst_port>eq \S+|neq \S+|lt \S+|gt \S+|range \S+ \S+|'\
                 'portgroup \S+)?'\
                 ' *(?<option>[a-zA-Z0-9-\/ ]*)*'
    end

    # Create a hash of all aces under give acl_name.
    def self.aces
      afis = %w(ip ipv6)
      hash = {}
      afis.each do |afi|
        @get_args = { afi: afi }
        instances = config_get('acl', 'all_acl', @get_args)
        next if instances.nil?
        instances.each do |name|
          hash[name] = Acl.new(name, @get_args[:afi], false)
          aces = config_get('acl', 'all_ace', acl_name: name)
          next if aces.nil?
          aces.each do |ace|
            item = Ace.new(name, ace[0].to_i, @get_args[:afi])
            item.seqno = ace[0].to_i
            item.action = ace[1]
            item.proto = ace[2]
            item.src_addr = ace[3]
            item.src_port = ace[4]
            item.dst_addr = ace[5]
            item.dst_port = ace[6]
            item.option_format = ace[7]
            hash[name] = {}
            hash[name][ace[0].to_i] = item
          end
        end
      end
      hash
    end

    # Destroy a router instance; disable feature on last instance
    def destroy
      config_ace('no')
    end

    # First create acl
    def config_ace(state='')
      @set_args[:state] = state
      config_set('acl', 'ace', @set_args)
    end

    # ----------
    # PROPERTIES
    # ----------
    # getter of seqno
    def seqno
      str = config_get('acl', 'ace', @get_args)
      return if str.nil?

      regexp = Regexp.new(@regexp_str)
      match = regexp.match(str)
      match[0]
    end

    # setter of seqno
    def seqno=(state)
      @set_args[:state] = state ? '' : 'no'
    end

    # getter of action
    def action
      str = config_get('acl', 'ace', @get_args)
      return if str.nil?

      regexp = Regexp.new(@regexp_str)
      match = regexp.match(str)
      match[1]
    end

    # setter of action
    def action=(action)
      @set_args[:action] = action
    end

    # getter of proto
    def proto
      str = config_get('acl', 'ace', @get_args)
      return if str.nil?

      regexp = Regexp.new(@regexp_str)
      match = regexp.match(str)
      match[2]
    end

    # setter of proto
    def proto=(proto)
      @set_args[:proto] = proto
    end

    # getter of src_addr
    def src_addr
      str = config_get('acl', 'ace', @get_args)
      return if str.nil?

      regexp = Regexp.new(@regexp_str)
      match = regexp.match(str)
      match[3]
    end

    # setter of src_addr
    def src_addr=(src_addr)
      @set_args[:src_addr] = src_addr
    end

    # getter of src_port
    def src_port
      str = config_get('acl', 'ace', @get_args)
      return if str.nil?

      regexp = Regexp.new(@regexp_str)
      match = regexp.match(str)
      match[5]
    end

    # setter of src_port_format
    def src_port=(src_port)
      @set_args[:src_port] = src_port
    end

    # getter of dst_addr_format
    def dst_addr
      str = config_get('acl', 'ace', @get_args)
      return if str.nil?

      regexp = Regexp.new(@regexp_str)
      match = regexp.match(str)
      match[6]
    end

    # setter of dst_addr_format
    def dst_addr=(dst_addr)
      @set_args[:dst_addr] = dst_addr
    end

    # getter of dst_port_format
    def dst_port
      str = config_get('acl', 'ace', @get_args)
      return if str.nil?

      regexp = Regexp.new(@regexp_str)
      match = regexp.match(str)
      match[7]
    end

    # setter of dst_port_format
    def dst_port=(src_port)
      @set_args[:dst_port] = src_port
    end

    # getter of option_format
    def option_format
      str = config_get('acl', 'ace', @get_args)
      return if str.nil?

      regexp = Regexp.new(@regexp_str)
      match = regexp.match(str)
      match[8]
    end

    # setter of option_format
    def option_format=(option)
      @set_args[:option_format] = option
    end
  end
end
