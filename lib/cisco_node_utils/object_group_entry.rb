#
# May 2017, Sai Chintalapudi
#
# Copyright (c) 2017 Cisco and/or its affiliates.
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
require_relative 'acl'
require_relative 'object_group'

module Cisco
  # node_utils class for object_group_entry
  class ObjectGroupEntry < NodeUtil
    attr_reader :afi, :type, :grp_name

    def initialize(afi, type, name, seqno)
      fail TypeError unless name.is_a?(String)
      fail ArgumentError unless type[/address|port/]
      @afi = Acl.afi_cli(afi)
      @type = type
      @grp_name = name
      @seqno = seqno
      og = ObjectGroup.object_groups[afi.to_s][type.to_s][name.to_s]
      fail "ObjectGroup #{afi} #{type} #{name} does not exist" if
        og.nil?
      set_args_keys_default
    end

    # Helper method to delete @set_args hash keys
    def set_args_keys_default
      @set_args = { afi: @afi, type: @type, grp_name: @grp_name, seqno: @seqno }
      @get_args = @set_args
    end

    # rubocop:disable Style/AccessorMethodName
    def set_args_keys(hash={})
      set_args_keys_default
      @set_args = @get_args.merge!(hash) unless hash.empty?
    end

    def destroy
      config_set('object_group', 'entry_destroy', @set_args)
    end

    def self.object_group_entries
      hash = {}
      grps = config_get('object_group', 'all_object_groups')
      return hash if grps.nil?
      grps.each do |afi, type, name|
        lafi = afi
        lafi = 'ipv4' if afi == 'ip'
        hash[lafi] ||= {}
        hash[lafi][type] ||= {}
        hash[lafi][type][name] ||= {}
        entries = config_get('object_group', 'all_entries',
                             afi:      Acl.afi_cli(lafi),
                             type:     type,
                             grp_name: name)
        next if entries.nil?
        entries.each do |seqno|
          hash[lafi][type][name][seqno] =
            ObjectGroupEntry.new(lafi, type, name, seqno)
        end
      end
      hash
    end

    def entry_get
      str = config_get('object_group', 'entry', @get_args)
      return nil if str.nil?
      str = str.strip

      # rubocop:disable Metrics/LineLength
      regexp = Regexp.new('(?<seqno>\d+)'\
                          ' *(?<address>host \S+|[:\.0-9a-fA-F]+ [:\.0-9a-fA-F]+|[:\.0-9a-fA-F]+\/\d+)?'\
                          ' *(?<port>range \S+ \S+|(lt|eq|gt|neq) \S+)?')
      # rubocop:enable Metrics/LineLength
      regexp.match(str)
    end

    def entry_set(attrs)
      if attrs.empty?
        attrs[:state] = 'no'
      else
        destroy if seqno
        attrs[:state] = ''
      end
      set_args_keys_default
      set_args_keys(attrs)
      [:address,
       :port,
      ].each do |p|
        attrs[p] = '' if attrs[p].nil?
        send(p.to_s + '=', attrs[p])
      end
      @get_args = @set_args
      config_set('object_group', 'entry', @set_args)
    end

    # PROPERTIES
    # ----------
    def seqno
      match = entry_get
      return nil if match.nil?
      match.names.include?('seqno') ? match[:seqno] : nil
    end

    def address
      match = entry_get
      return nil if match.nil?
      addr = match[:address]
      return nil if addr.nil?
      # Normalize addr. Some platforms zero_pad ipv6 addrs.
      addr.gsub!(/^0*/, '').gsub!(/:0*/, ':')
      addr
    end

    def address=(address)
      @set_args[:address] = address
    end

    def port
      match = entry_get
      return nil if match.nil?
      match.names.include?('port') ? match[:port] : nil
    end

    def port=(port)
      @set_args[:port] = port
    end
  end # class
end # module
