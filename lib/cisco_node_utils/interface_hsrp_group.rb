#
# October 2016, Sai Chintalapudi
#
# Copyright (c) 2016 Cisco and/or its affiliates.
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
require_relative 'interface'
require_relative 'interface_hsrp'

module Cisco
  # node_utils class for interface_hsrp_group
  class InterfaceHsrpGroup < NodeUtil
    attr_reader :name, :group, :iptype

    def initialize(interface, group_id, ip_type, instantiate=true)
      fail TypeError unless interface.is_a?(String)
      fail ArgumentError unless ip_type[/ipv4|ipv6/]
      @name = interface.downcase
      @group = group_id
      @iptype = ip_type

      set_args_keys_default
      create if instantiate
    end

    def self.hsrp_groups
      hash = {}
      Interface.interfaces.each do|intf, _obj|
        groups = config_get('interface_hsrp_group', 'hsrp_groups', name: intf)
        next if groups.nil?
        hash[intf] = {}
        groups.each do |id, type|
          iptype = type
          iptype = 'ipv4' if type.nil?
          hash[intf][id] ||= {}
          hash[intf][id][iptype] = InterfaceHsrpGroup.new(intf, id, iptype)
        end
      end
      hash
    end

    # Helper method to delete @set_args hash keys
    def set_args_keys_default
      @set_args = { name: @name, group: @group, iptype: iptype }
      @set_args[:iptype] = '' if @iptype == 'ipv4'
      @get_args = @set_args
    end

    # rubocop:disable Style/AccessorMethodName
    def set_args_keys(hash={})
      set_args_keys_default
      @set_args = @get_args.merge!(hash) unless hash.empty?
    end

    # Create one router ospf area virtual-link instance
    def create
      Feature.hsrp_enable
      set_args_keys(state: '')
      config_set('interface_hsrp_group', 'hsrp_groups', @set_args)
    end

    def destroy
      return unless Feature.hsrp_enabled?
      set_args_keys(state: 'no', iptype: @iptype)
      config_set('interface_hsrp_group', 'hsrp_groups', @set_args)
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    # This CLI is very complicated, it can take many forms
    # authentication text Test
    # authentication md5 key-chain abcd
    # authentication md5 key-string 7 => 7 is key-string
    # authentication md5 key-string 7 12345678901234567890
    # authentication md5 key-string ABCXYZ => enctype is 0
    # authentication md5 key-string ABCXYZ compatibility
    # authentication md5 key-string ABCXYZ compatibility timeout 22
    # authentication md5 key-string ABCXYZ timeout 22
    # authentication md5 key-string 7 12345678901234567890 timeout 22
    # authentication md5 key-string 7 123456789 compatibility timeout 22
    def authentication
      hash = {}
      hash[:auth_type] = default_authentication_auth_type
      hash[:key_type] = default_authentication_key_type
      hash[:enc_type] = default_authentication_enc_type
      hash[:password] = default_authentication_string
      hash[:compat] = default_authentication_compatibility
      hash[:timeout] = default_authentication_timeout
      str = config_get('interface_hsrp_group', 'authentication', @get_args)
      return hash if str.nil?
      params = str.split
      if params[0] == 'text'
        hash[:password] = params[1]
      else
        hash[:auth_type] = 'md5'
        hash[:key_type] = params[1]
        if hash[:key_type] == 'key-chain'
          hash[:password] = params[2]
        else
          ki = params.index('key-string')
          next_elem = params[ki + 1]
          if next_elem == '7' && params[ki + 2].nil?
            hash[:password] = '7'
          elsif next_elem == '7' && !params[ki + 2].nil?
            hash[:enc_type] = '7'
            hash[:password] = params[ki + 2]
          else
            hash[:password] = next_elem
          end
          params.delete_at(params.index(hash[:password]))
          hash[:compat] = true unless params.index('compatibility').nil?
          hash[:timeout] = params[params.index('timeout') + 1].to_i unless
            params.index('timeout').nil?
        end
      end
      hash
    end

    def authentication_auth_type
      authentication[:auth_type]
    end

    def authentication_auth_type=(val)
      @set_args[:authtype] = val
      @set_args[:authtype] = 'text' if val == 'cleartext'
    end

    def default_authentication_auth_type
      config_get_default('interface_hsrp_group', 'authentication_auth_type')
    end

    def authentication_key_type
      authentication[:key_type]
    end

    def authentication_key_type=(val)
      @set_args[:keytype] = val
    end

    def default_authentication_key_type
      config_get_default('interface_hsrp_group', 'authentication_key_type')
    end

    def authentication_enc_type
      authentication[:enc_type]
    end

    def authentication_enc_type=(val)
      @set_args[:enctype] = val
    end

    def default_authentication_enc_type
      config_get_default('interface_hsrp_group', 'authentication_enc_type')
    end

    def authentication_string
      authentication[:password]
    end

    def authentication_string=(val)
      @set_args[:passwd] = val
    end

    def default_authentication_string
      config_get_default('interface_hsrp_group', 'authentication_string')
    end

    def authentication_compatibility
      authentication[:compat]
    end

    def authentication_compatibility=(val)
      @set_args[:compatible] = val ? 'compatibility' : ''
    end

    def default_authentication_compatibility
      config_get_default('interface_hsrp_group', 'authentication_compatibility')
    end

    def authentication_timeout
      authentication[:timeout]
    end

    def authentication_timeout=(val)
      @set_args[:tval] = val
      @set_args[:timeout] = 'timeout'
    end

    def default_authentication_timeout
      config_get_default('interface_hsrp_group', 'authentication_timeout')
    end

    def authentication_set(attrs)
      set_args_keys_default
      # reset the authentication first
      @set_args[:state] = 'no'
      @set_args[:passwd] = ''
      @set_args[:authtype] = @set_args[:keytype] = @set_args[:enctype] = ''
      @set_args[:compatible] = @set_args[:timeout] = @set_args[:tval] = ''
      config_set('interface_hsrp_group', 'authentication', @set_args)
      set_args_keys(attrs)
      [:authentication_auth_type,
       :authentication_key_type,
       :authentication_enc_type,
       :authentication_string,
       :authentication_compatibility,
       :authentication_timeout,
      ].each do |p|
        send(p.to_s + '=', attrs[p]) unless attrs[p].nil?
      end
      return if @set_args[:passwd] == default_authentication_string
      @set_args[:state] = ''
      if @set_args[:authtype] == 'text'
        @set_args[:keytype] = @set_args[:enctype] = ''
        @set_args[:compatible] = @set_args[:timeout] = @set_args[:tval] = ''
      elsif @set_args[:keytype] == default_authentication_key_type
        @set_args[:enctype] = @set_args[:compatible] = ''
        @set_args[:timeout] = @set_args[:tval] = ''
      end
      config_set('interface_hsrp_group', 'authentication', @set_args)
    end

    # CLI returns mac_addr in xxxx.xxxx.xxxx format
    # so convert it to xx:xx:xx:xx:xx:xx format
    def mac_addr
      mac = config_get('interface_hsrp_group', 'mac_addr', @get_args)
      return default_mac_addr unless mac
      mac.tr!('.', '')
      [2, 5, 8, 11, 14].each do |i|
        mac.insert i, ':'
      end
      mac
    end

    # CLI expects mac_addr to be in xxxx.xxxx.xxxx format
    # so convert from xx:xx:xx:xx:xx:xx format
    def mac_addr=(val)
      state = val ? '' : 'no'
      mac = val ? val : ''
      if val
        mac.tr!(':', '')
        mac.insert 4, '.'
        mac.insert 9, '.'
      end
      set_args_keys(state: state, mac: mac)
      config_set('interface_hsrp_group', 'mac_addr', @set_args)
    end

    def default_mac_addr
      config_get_default('interface_hsrp_group', 'mac_addr')
    end

    def name
      config_get('interface_hsrp_group', 'name', @get_args)
    end

    def name=(val)
      state = val ? '' : 'no'
      word = val ? val : ''
      set_args_keys(state: state, word: word)
      config_set('interface_hsrp_group', 'name', @set_args)
    end

    def default_name
      config_get_default('interface_hsrp_group', 'name')
    end
  end # class
end # module
