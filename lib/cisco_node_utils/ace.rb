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
    attr_reader :acl_name, :seqno, :afi

    # acl_name is name of acl
    # seqno is sequence number of ace
    # afi is either v4 or v6
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

    # common ace getter
    def ace_get
      str = config_get('acl', 'ace', @get_args)
      return nil if str.nil?

      regexp = Regexp.new('(?<seqno>\d+) (?<action>\S+)'\
                 ' *(?<proto>\d+|\S+)'\
                 ' *(?<src_addr>any|host \S+|\S+\/\d+|\S+ [:\.0-9a-fA-F]+|'\
                 'addrgroup \S+)*'\
                 ' *(?<src_port>eq \S+|neq \S+|lt \S+|''gt \S+|range \S+ \S+|'\
                 'portgroup \S+)?'\
                 ' *(?<dst_addr>any|host \S+|\S+\/\d+|\S+ [:\.0-9a-fA-F]+|'\
                 'addrgroup \S+)'\
                 ' *(?<dst_port>eq \S+|neq \S+|lt \S+|gt \S+|range \S+ \S+|'\
                 'portgroup \S+)?'\
                 ' *(?<option_format>[a-zA-Z0-9\-\/ ]*)*')
      regexp.match(str)
    end

    # Create a hash of all aces under give acl_name.
    def self.aces
      afis = %w(ip ipv6)
      hash = {}
      afis.each do |afi|
        acls = config_get('acl', 'all_acls', afi: afi)
        next if acls.nil?

        acls.each do |acl_name|
          hash[acl_name] = {}
          aces = config_get('acl', 'all_aces', afi: afi, acl_name: acl_name)
          next if aces.nil?

          aces.each do |seqno|
            hash[acl_name][seqno] = Ace.new(afi, acl_name, seqno.to_i)
          end
        end
        # puts "hash #{hash}"
      end
      hash
    end

    # common setter. Put the values you need in a hash and pass it in.
    # attrs = {:action=>'permit', :proto=>'ip', :src =>'host 1.1.1.1'}
    def ace_set(attrs)
      state = attrs.empty? ? 'no ' : ''
      @set_args[:state] = state
      @set_args.merge!(attrs) unless attrs.empty?
      config_set('acl', 'ace', @set_args)
    end

    # PROPERTIES
    # ----------
    # getter of action
    def action
      match = ace_get
      return nil if match.nil?

      match[:action]
    end

    # setter of action
    def action=(action)
      @set_args[:action] = action
    end

    # getter of proto
    def proto
      match = ace_get
      return nil if match.nil?

      match[:proto]
    end

    # setter of proto
    def proto=(proto)
      @set_args[:proto] = proto
    end

    # getter of src_addr
    def src_addr
      match = ace_get
      return nil if match.nil?

      match[:src_addr]
    end

    # setter of src_addr
    def src_addr=(src_addr)
      @set_args[:src_addr] = src_addr
    end

    # getter of src_port
    def src_port
      match = ace_get
      return nil if match.nil?

      match[:src_port]
    end

    # setter of src_port_format
    def src_port=(src_port)
      @set_args[:src_port] = src_port
    end

    # getter of dst_addr_format
    def dst_addr
      match = ace_get
      return nil if match.nil?

      match[:dst_addr]
    end

    # setter of dst_addr_format
    def dst_addr=(dst_addr)
      @set_args[:dst_addr] = dst_addr
    end

    # getter of dst_port_format
    def dst_port
      match = ace_get
      return nil if match.nil?

      match[:dst_port]
    end

    # setter of dst_port_format
    def dst_port=(src_port)
      @set_args[:dst_port] = src_port
    end

    # getter of option_format
    def option_format
      match = ace_get
      return nil if match.nil?

      match[:option_format]
    end

    # setter of option_format
    def option_format=(option)
      @set_args[:option_format] = option
    end
  end
end
