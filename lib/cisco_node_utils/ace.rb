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
    attr_reader :afi, :acl_name, :seqno

    def initialize(afi, acl_name, seqno)
      @set_args = @get_args =
        { afi: Acl.afi_cli(afi), acl_name: acl_name.to_s, seqno: seqno.to_s }
    end

    # Create a hash of all aces under a given acl_name.
    def self.aces
      afis = %w(ipv4 ipv6)
      hash = {}
      afis.each do |afi|
        acls = config_get('acl', 'all_acls', afi: Acl.afi_cli(afi))
        next if acls.nil?

        acls.each do |acl_name|
          hash[acl_name] = {}
          aces = config_get('acl', 'all_aces',
                            afi: Acl.afi_cli(afi), acl_name: acl_name)
          next if aces.nil?

          aces.each do |seqno|
            hash[acl_name][seqno] = Ace.new(afi, acl_name, seqno)
          end
        end
      end
      hash
    end

    # common ace getter
    def ace_get
      str = config_get('acl', 'ace', @get_args)
      return nil if str.nil?

      # remark is a description field, needs a separate regex
      # Example: <MatchData "20 remark foo bar" seqno:"20" remark:"foo bar">
      remark = str.match(/(?<seqno>\d+) remark (?<remark>.*)/)
      return remark unless remark.nil?

      # rubocop:disable Metrics/LineLength
      regexp = Regexp.new('(?<seqno>\d+) (?<action>\S+)'\
                 ' *(?<proto>\d+|\S+)'\
                 ' *(?<src_addr>any|host \S+|\S+\/\d+|\S+ [:\.0-9a-fA-F]+|addrgroup \S+)*'\
                 ' *(?<src_port>eq \S+|neq \S+|lt \S+|''gt \S+|range \S+ \S+|portgroup \S+)?'\
                 ' *(?<dst_addr>any|host \S+|\S+\/\d+|\S+ [:\.0-9a-fA-F]+|addrgroup \S+)'\
                 ' *(?<dst_port>eq \S+|neq \S+|lt \S+|gt \S+|range \S+ \S+|portgroup \S+)?'\
                 ' *(?<option_format>[a-zA-Z0-9\-\/ ]*)*')
      # rubocop:enable Metrics/LineLength
      regexp.match(str)
    end

    # common ace setter. Put the values you need in a hash and pass it in.
    # attrs = {:action=>'permit', :proto=>'tcp', :src =>'host 1.1.1.1'}
    def ace_set(attrs)
      @set_args[:state] = attrs.empty? ? 'no ' : ''
      @set_args.merge!(attrs) unless attrs.empty?
      cmd = @set_args[:remark] ? 'ace_remark' : 'ace'
      config_set('acl', cmd, @set_args)
    end

    # PROPERTIES
    # ----------
    def action
      match = ace_get
      return nil if match.nil?
      match[:action]
    end

    def action=(action)
      @set_args[:action] = action
    end

    def remark
      match = ace_get
      return nil if match.nil?
      match[:remark]
    end

    def remark=(remark)
      @set_args[:remark] = remark
    end

    def proto
      match = ace_get
      return nil if match.nil?
      match[:proto]
    end

    def proto=(proto)
      @set_args[:proto] = proto # TBD ip vs ipv4
    end

    def src_addr
      match = ace_get
      return nil if match.nil?
      match[:src_addr]
    end

    def src_addr=(src_addr)
      @set_args[:src_addr] = src_addr
    end

    def src_port
      match = ace_get
      return nil if match.nil?
      match[:src_port]
    end

    def src_port=(src_port)
      @set_args[:src_port] = src_port
    end

    def dst_addr
      match = ace_get
      return nil if match.nil?
      match[:dst_addr]
    end

    def dst_addr=(dst_addr)
      @set_args[:dst_addr] = dst_addr
    end

    def dst_port
      match = ace_get
      return nil if match.nil?
      match[:dst_port]
    end

    def dst_port=(src_port)
      @set_args[:dst_port] = src_port
    end

    # TBD option_format is currently a catch-all for all other ace properties.
    # This will likely need to be reworked to support explicit properties.
    def option_format
      match = ace_get
      return nil if match.nil?
      match[:option_format]
    end

    def option_format=(option)
      @set_args[:option_format] = option
    end
  end
end
