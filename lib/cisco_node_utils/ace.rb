# Copyright (c) 2015-2018 Cisco and/or its affiliates.
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

require 'ipaddr'
require_relative 'node_util'

module Cisco
  # Ace - node utility class for Ace Configuration
  class Ace < NodeUtil
    attr_reader :afi, :acl_name

    def initialize(afi, acl_name, seqno)
      @afi = Acl.afi_cli(afi)
      @acl_name = acl_name.to_s
      @seqno = seqno.to_s
      set_args_keys_default
    end

    # Create a hash of all aces under a given acl_name.
    def self.aces
      afis = %w(ipv4 ipv6)
      hash = {}
      afis.each do |afi|
        hash[afi] = {}
        acls = config_get('acl', 'all_acls', afi: Acl.afi_cli(afi))
        next if acls.nil?

        acls.each do |acl_name|
          hash[afi][acl_name] = {}
          aces = config_get('acl', 'all_aces',
                            afi: Acl.afi_cli(afi), acl_name: acl_name)
          next if aces.nil?

          aces.each do |seqno|
            hash[afi][acl_name][seqno] = Ace.new(afi, acl_name, seqno)
          end
        end
      end
      hash
    end

    def destroy
      set_args_keys(state: 'no')
      config_set('acl', 'ace_destroy', @set_args)
    end

    def set_args_keys_default
      keys = { afi: @afi, acl_name: @acl_name, seqno: @seqno }
      @get_args = @set_args = keys
    end

    # rubocop:disable Style/AccessorMethodName
    def set_args_keys(hash={})
      set_args_keys_default
      @set_args = @get_args.merge!(hash) unless hash.empty?
    end

    # common ace getter
    def ace_get
      str = config_get('acl', 'ace', @get_args)
      return nil if str.nil?

      remark = Regexp.new('(?<seqno>\d+) remark (?<remark>.*)').match(str)
      return remark unless remark.nil?

      # for icmp things are different
      return icmp_ace_get(str) if str.include?('icmp')

      # rubocop:disable Metrics/LineLength
      regexp = Regexp.new('(?<seqno>\d+) (?<action>\S+)'\
                 ' *(?<proto>\d+|\S+)'\
                 ' *(?<src_addr>any|host \S+|[:\.0-9a-fA-F]+ [:\.0-9a-fA-F]+|[:\.0-9a-fA-F]+\/\d+|addrgroup \S+)'\
                 ' *(?<src_port>range \S+ \S+|(lt|eq|gt|neq|portgroup) \S+)?'\
                 ' *(?<dst_addr>any|host \S+|[:\.0-9a-fA-F]+ [:\.0-9a-fA-F]+|[:\.0-9a-fA-F]+\/\d+|addrgroup \S+)'\
                 ' *(?<dst_port>range \S+ \S+|(lt|eq|gt|neq|portgroup) \S+)?'\
                 ' *(?<tcp_flags>(ack *|fin *|urg *|syn *|psh *|rst *)*)?'\
                 ' *(?<established>established)?'\
                 ' *(?<precedence>precedence \S+)?'\
                 ' *(?<dscp>dscp \S+)?'\
                 ' *(?<time_range>time-range \S+)?'\
                 ' *(?<packet_length>packet-length (range \d+ \d+|(lt|eq|gt|neq) \d+))?'\
                 ' *(?<ttl>ttl \d+)?'\
                 ' *(?<http_method>http-method (\d+|connect|delete|get|head|post|put|trace))?'\
                 ' *(?<tcp_option_length>tcp-option-length \d+)?'\
                 ' *(?<redirect>redirect \S+)?'\
                 ' *(?<log>log)?')
      # rubocop:enable Metrics/LineLength
      regexp.match(str)
    end

    # icmp ace getter
    def icmp_ace_get(str)
      # rubocop:disable Metrics/LineLength
      regexp = Regexp.new('(?<seqno>\d+) (?<action>\S+)'\
                 ' *(?<proto>\d+|\S+)'\
                 ' *(?<src_addr>any|host \S+|[:\.0-9a-fA-F]+ [:\.0-9a-fA-F]+|[:\.0-9a-fA-F]+\/\d+|addrgroup \S+)'\
                 ' *(?<dst_addr>any|host \S+|[:\.0-9a-fA-F]+ [:\.0-9a-fA-F]+|[:\.0-9a-fA-F]+\/\d+|addrgroup \S+)'\
                 ' *(?<proto_option>\S+)?'\
                 ' *(?<precedence>precedence \S+)?'\
                 ' *(?<redirect>redirect \S+)?'\
                 ' *(?<dscp>dscp \S+)?'\
                 ' *(?<time_range>time-range \S+)?'\
                 ' *(?<packet_length>packet-length (range \d+ \d+|(lt|eq|gt|neq) \d+))?'\
                 ' *(?<ttl>ttl \d+)?'\
                 ' *(?<vlan>vlan \d+)?'\
                 ' *(?<set_erspan_gre_proto>set-erspan-gre-proto \d+)?'\
                 ' *(?<set_erspan_dscp>set-erspan-dscp \d+)?')
      regexp_no_proto_option = Regexp.new('(?<seqno>\d+) (?<action>\S+)'\
                 ' *(?<proto>\d+|\S+)'\
                 ' *(?<src_addr>any|host \S+|[:\.0-9a-fA-F]+ [:\.0-9a-fA-F]+|[:\.0-9a-fA-F]+\/\d+|addrgroup \S+)'\
                 ' *(?<dst_addr>any|host \S+|[:\.0-9a-fA-F]+ [:\.0-9a-fA-F]+|[:\.0-9a-fA-F]+\/\d+|addrgroup \S+)'\
                 ' *(?<precedence>precedence \S+)?'\
                 ' *(?<redirect>redirect \S+)?'\
                 ' *(?<dscp>dscp \S+)?'\
                 ' *(?<time_range>time-range \S+)?'\
                 ' *(?<packet_length>packet-length (range \d+ \d+|(lt|eq|gt|neq) \d+))?'\
                 ' *(?<ttl>ttl \d+)?'\
                 ' *(?<vlan>vlan \d+)?'\
                 ' *(?<set_erspan_gre_proto>set-erspan-gre-proto \d+)?'\
                 ' *(?<set_erspan_dscp>set-erspan-dscp \d+)?')
      temp = regexp.match(str)
      po = temp[:proto_option]
      if po.nil?
        return temp
      # redirect can be proto_option or an actual redirect to interface
      elsif po.strip.match(/redirect$/)
        if str.match(/Ethernet|port-channel/)
          # if proto_option is given as redirect and also redirect to intf
          # we need to do extra processing
          return temp if check_redirect_repeat(str)
          return regexp_no_proto_option.match(str)
        end
      # the reserved keywords check
      elsif po.strip.match(/precedence$|dscp$|time-range$|packet-length$|ttl$|vlan$|set-erspan-gre-proto$|set-erspan-dscp$|log$/)
        return regexp_no_proto_option.match(str)
      else
        return temp
      end
      # rubocop:enable Metrics/LineLength
    end

    # common ace setter. Put the values you need in a hash and pass it in.
    # attrs = {:action=>'permit', :proto=>'tcp', :src =>'host 1.1.1.1'}
    def ace_set(attrs)
      if attrs.empty?
        attrs[:state] = 'no'
      else
        # remove existing ace first
        destroy if seqno
        attrs[:state] = ''
      end

      if attrs[:remark]
        cmd = 'ace_remark'
        set_args_keys(attrs)
      else
        cmd = 'ace'
        set_args_keys_default
        set_args_keys(attrs)
        [:action,
         :proto,
         :src_addr,
         :src_port,
         :dst_addr,
         :dst_port,
         :tcp_flags,
         :established,
         :precedence,
         :dscp,
         :time_range,
         :packet_length,
         :ttl,
         :http_method,
         :tcp_option_length,
         :redirect,
         :log,
         :proto_option,
         :set_erspan_dscp,
         :set_erspan_gre_proto,
         :vlan,
        ].each do |p|
          attrs[p] = '' if attrs[p].nil?
          send(p.to_s + '=', attrs[p])
        end
        @get_args = @set_args
      end
      config_set('acl', cmd, @set_args)
    end

    def valid_ipv6?(addr)
      begin
        ret = IPAddr.new(addr.split[0]).ipv6?
      rescue
        ret = false
      end
      ret
    end

    def check_redirect_repeat(str)
      return false unless str.include?('redirect')
      nstr = str.sub('redirect', '').strip
      nstr.include?('redirect') ? true : false
    end

    # PROPERTIES
    # ----------
    def seqno
      match = ace_get
      return nil if match.nil?
      match.names.include?('seqno') ? match[:seqno] : nil
    end

    def action
      match = ace_get
      return nil if match.nil?
      match.names.include?('action') ? match[:action] : nil
    end

    def action=(action)
      @set_args[:action] = action
    end

    def remark
      match = ace_get
      return nil if match.nil?
      match.names.include?('remark') ? match[:remark] : nil
    end

    def remark=(remark)
      @set_args[:remark] = remark
    end

    def proto
      match = ace_get
      return nil if match.nil?
      match.names.include?('proto') ? match[:proto] : nil
    end

    def proto=(proto)
      @set_args[:proto] = proto # TBD ip vs ipv4
    end

    def src_addr
      match = ace_get
      return nil if match.nil? || !match.names.include?('src_addr')
      addr = match[:src_addr]
      # Normalize addr. Some platforms zero_pad ipv6 addrs.
      addr.gsub!(/^0*/, '').gsub!(/:0*/, ':') if valid_ipv6?(addr)
      addr
    end

    def src_addr=(src_addr)
      @set_args[:src_addr] = src_addr
    end

    def src_port
      match = ace_get
      return nil if match.nil?
      match.names.include?('src_port') ? match[:src_port] : nil
    end

    def src_port=(src_port)
      @set_args[:src_port] = src_port
    end

    def dst_addr
      match = ace_get
      return nil if match.nil? || !match.names.include?('dst_addr')
      addr = match[:dst_addr]
      # Normalize addr. Some platforms zero_pad ipv6 addrs.
      addr.gsub!(/^0*/, '').gsub!(/:0*/, ':') if valid_ipv6?(addr)
      addr
    end

    def dst_addr=(dst_addr)
      @set_args[:dst_addr] = dst_addr
    end

    def dst_port
      match = ace_get
      return nil if match.nil?
      match.names.include?('dst_port') ? match[:dst_port] : nil
    end

    def dst_port=(src_port)
      @set_args[:dst_port] = src_port
    end

    def tcp_flags
      match = ace_get
      return nil if match.nil?
      match.names.include?('tcp_flags') ? match[:tcp_flags].strip : nil
    end

    def tcp_flags=(tcp_flags)
      @set_args[:tcp_flags] = tcp_flags.strip
    end

    def established
      match = ace_get
      return nil unless remark.nil?
      return false if match.nil?
      return false unless match.names.include?('established')
      match[:established] == 'established' ? true : false
    end

    def established=(established)
      @set_args[:established] = established.to_s == 'true' ? 'established' : ''
    end

    def precedence
      Utils.extract_value(ace_get, 'precedence')
    end

    def precedence=(precedence)
      @set_args[:precedence] = Utils.attach_prefix(precedence, :precedence)
    end

    def dscp
      Utils.extract_value(ace_get, 'dscp')
    end

    def dscp=(dscp)
      @set_args[:dscp] = Utils.attach_prefix(dscp, :dscp)
    end

    def vlan
      Utils.extract_value(ace_get, 'vlan')
    end

    def vlan=(vlan)
      @set_args[:vlan] = Utils.attach_prefix(vlan, :vlan)
    end

    def set_erspan_dscp
      Utils.extract_value(ace_get, 'set_erspan_dscp', 'set-erspan-dscp')
    end

    def set_erspan_dscp=(set_erspan_dscp)
      @set_args[:set_erspan_dscp] = Utils.attach_prefix(set_erspan_dscp,
                                                        :set_erspan_dscp,
                                                        'set-erspan-dscp')
    end

    def set_erspan_gre_proto
      Utils.extract_value(ace_get, 'set_erspan_gre_proto',
                          'set-erspan-gre-proto')
    end

    def set_erspan_gre_proto=(set_erspan_gre_proto)
      @set_args[:set_erspan_gre_proto] =
          Utils.attach_prefix(set_erspan_gre_proto,
                              :set_erspan_gre_proto,
                              'set-erspan-gre-proto')
    end

    def time_range
      Utils.extract_value(ace_get, 'time_range', 'time-range')
    end

    def time_range=(time_range)
      @set_args[:time_range] = Utils.attach_prefix(time_range,
                                                   :time_range,
                                                   'time-range')
    end

    def packet_length
      Utils.extract_value(ace_get, 'packet_length', 'packet-length')
    end

    def packet_length=(packet_length)
      @set_args[:packet_length] = Utils.attach_prefix(packet_length,
                                                      :packet_length,
                                                      'packet-length')
    end

    def ttl
      Utils.extract_value(ace_get, 'ttl')
    end

    def ttl=(ttl)
      @set_args[:ttl] = Utils.attach_prefix(ttl, :ttl)
    end

    def http_method
      Utils.extract_value(ace_get, 'http_method', 'http-method')
    end

    def http_method=(http_method)
      @set_args[:http_method] = Utils.attach_prefix(http_method,
                                                    :http_method,
                                                    'http-method')
    end

    def tcp_option_length
      Utils.extract_value(ace_get, 'tcp_option_length', 'tcp-option-length')
    end

    def tcp_option_length=(tcp_option_length)
      @set_args[:tcp_option_length] = Utils.attach_prefix(tcp_option_length,
                                                          :tcp_option_length,
                                                          'tcp-option-length')
    end

    def redirect
      Utils.extract_value(ace_get, 'redirect')
    end

    def redirect=(redirect)
      @set_args[:redirect] = Utils.attach_prefix(redirect, :redirect)
    end

    def proto_option
      match = ace_get
      return nil if match.nil? || proto != 'icmp' || !remark.nil?
      # fragments is nvgen at a different location than all other
      # proto_option
      if config_get('acl', 'ace', @get_args).include?('fragments')
        return 'fragments'
      end
      # log is special case
      return nil if !match.names.include?('proto_option') ||
                    match[:proto_option] == 'log'
      match[:proto_option]
    end

    def proto_option=(proto_option)
      @set_args[:proto_option] = proto_option
    end

    def log
      return nil unless remark.nil?
      config_get('acl', 'ace', @get_args).include?('log') ? true : false
    end

    def log=(log)
      @set_args[:log] = log.to_s == 'true' ? 'log' : ''
    end
  end
end
