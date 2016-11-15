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

    def self.groups
      hash = {}
      return hash unless Feature.hsrp_enabled?
      Interface.interfaces.each do|intf, _obj|
        groups = config_get('interface_hsrp_group', 'groups', name: intf)
        next if groups.nil?
        hash[intf] = {}
        groups.each do |id, type|
          iptype = type
          iptype = 'ipv4' if type.nil?
          hash[intf][id] ||= {}
          hash[intf][id][iptype] =
            InterfaceHsrpGroup.new(intf, id, iptype, false)
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

    # Create one interface hsrp group instance
    def create
      Feature.hsrp_enable
      set_args_keys(state: '')
      config_set('interface_hsrp_group', 'groups', @set_args)
    end

    def destroy
      return unless Feature.hsrp_enabled?
      # for ipv4 types, 'no' cmd needs the type to be specified
      # explicitly if another ipv6 group exists with the same
      # group id
      set_args_keys(state: 'no', iptype: @iptype)
      config_set('interface_hsrp_group', 'groups', @set_args)
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
      regexp = Regexp.new('(?<authtype>text|md5)'\
           ' *(?<keytype>key-chain|key-string|\S+)'\
           ' *(?<enctype>7|\S+)?'\
           ' *(?<keystring>\S+)?')
      params = regexp.match(str)
      if params[:authtype] == 'text'
        hash[:password] = params[:keytype]
      else
        hash[:auth_type] = 'md5'
        hash[:key_type] = params[:keytype]
        if hash[:key_type] == 'key-chain'
          hash[:password] = params[:enctype]
        else
          if params[:enctype] == '7' && params[:keystring].nil?
            hash[:password] = '7'
          elsif params[:enctype] == '7' && !params[:keystring].nil?
            hash[:enc_type] = '7'
            hash[:password] = params[:keystring]
          else
            hash[:password] = params[:enctype]
          end
          # get rid of password from str just in case the password is
          # compatibility or timeout
          str.sub!(hash[:password], '')
          hash[:compat] = true if str.include?('compatibility')
          hash[:timeout] = str.split.last.to_i if str.include?('timeout')
        end
      end
      hash
    end

    def authentication_auth_type
      authentication[:auth_type]
    end

    def authentication_auth_type=(val)
      @set_args[:authtype] = val
      @set_args[:authtype] = 'text' if val.to_s == 'cleartext'
    end

    def default_authentication_auth_type
      config_get_default('interface_hsrp_group', 'authentication_auth_type')
    end

    def authentication_key_type
      authentication[:key_type]
    end

    def authentication_key_type=(val)
      @set_args[:keytype] = val.to_s
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

    def ipv4_enable
      return default_ipv4_enable if @iptype == 'ipv6'
      ip = config_get('interface_hsrp_group', 'ipv4_vip', @get_args)
      ip.empty? ? false : true
    end

    def default_ipv4_enable
      config_get_default('interface_hsrp_group', 'ipv4_enable')
    end

    def ipv4_vip
      return default_ipv4_vip if @iptype == 'ipv6'
      ip = config_get('interface_hsrp_group', 'ipv4_vip', @get_args)
      return default_ipv4_vip unless ip
      arr = ip.split
      arr[1] ? arr[1] : default_ipv4_vip
    end

    def ipv4_vip_set(ipenable, vip)
      return if @iptype == 'ipv6'
      # reset it first
      set_args_keys(state: 'no', vip: '')
      config_set('interface_hsrp_group', 'ipv4_vip', @set_args)
      return unless ipenable
      vip = vip ? vip : ''
      set_args_keys(state: '', vip: vip)
      config_set('interface_hsrp_group', 'ipv4_vip', @set_args)
    end

    def default_ipv4_vip
      config_get_default('interface_hsrp_group', 'ipv4_vip')
    end

    def ipv6_autoconfig
      config_get('interface_hsrp_group', 'ipv6_autoconfig', @get_args)
    end

    def ipv6_autoconfig=(val)
      state = val ? '' : 'no'
      set_args_keys(state: state)
      config_set('interface_hsrp_group', 'ipv6_autoconfig', @set_args)
    end

    def default_ipv6_autoconfig
      config_get_default('interface_hsrp_group', 'ipv6_autoconfig')
    end

    def ipv6_vip
      return default_ipv6_vip if @iptype == 'ipv4'
      list = config_get('interface_hsrp_group', 'ipv6_vip', @get_args)
      # remove autoconfig from the list
      list.delete('autoconfig')
      list
    end

    def ipv6_vip=(list)
      # reset the current list
      cur = ipv6_vip
      cur.each do |addr|
        state = 'no'
        vip = addr
        set_args_keys(state: state, vip: vip)
        config_set('interface_hsrp_group', 'ipv6_vip', @set_args)
      end
      list.each do |addr|
        state = ''
        vip = addr
        set_args_keys(state: state, vip: vip)
        config_set('interface_hsrp_group', 'ipv6_vip', @set_args)
      end
    end

    def default_ipv6_vip
      config_get_default('interface_hsrp_group', 'ipv6_vip')
    end

    # CLI returns mac_addr in xxxx.xxxx.xxxx format
    # so convert it to xx:xx:xx:xx:xx:xx format
    def mac_addr
      mac = config_get('interface_hsrp_group', 'mac_addr', @get_args)
      return default_mac_addr unless mac
      mac.tr('.', '').scan(/.{1,2}/).join(':')
    end

    # CLI expects mac_addr to be in xxxx.xxxx.xxxx format
    # so convert from xx:xx:xx:xx:xx:xx format
    def mac_addr=(val)
      state = val ? '' : 'no'
      mac = val ? val.tr(':', '').scan(/.{1,4}/).join('.') : ''
      set_args_keys(state: state, mac: mac)
      config_set('interface_hsrp_group', 'mac_addr', @set_args)
    end

    def default_mac_addr
      config_get_default('interface_hsrp_group', 'mac_addr')
    end

    def group_name
      config_get('interface_hsrp_group', 'group_name', @get_args)
    end

    def group_name=(val)
      state = val ? '' : 'no'
      word = val ? val : ''
      set_args_keys(state: state, word: word)
      config_set('interface_hsrp_group', 'group_name', @set_args)
    end

    def default_group_name
      config_get_default('interface_hsrp_group', 'group_name')
    end

    # The CLI can take forms like:
    # preempt
    # preempt delay minimum 3 reload 10 sync 15
    def preempt_get
      hash = {}
      hash[:preempt] = default_preempt
      hash[:minimum] = default_preempt_delay_minimum
      hash[:reload] = default_preempt_delay_reload
      hash[:sync] = default_preempt_delay_sync
      arr = config_get('interface_hsrp_group', 'preempt', @get_args)
      if arr
        hash[:preempt] = true
        hash[:minimum] = arr[0]
        hash[:reload] = arr[1]
        hash[:sync] = arr[2]
      end
      hash
    end

    def preempt
      preempt_get[:preempt]
    end

    def preempt_delay_minimum
      preempt_get[:minimum].to_i
    end

    def preempt_delay_reload
      preempt_get[:reload].to_i
    end

    def preempt_delay_sync
      preempt_get[:sync].to_i
    end

    def preempt_set(pree, min, rel, sy)
      if pree
        set_args_keys(state: '', delay: 'delay', minimum: 'minimum',
                      minval: min, reload: 'reload', relval: rel,
                      sync: 'sync', syncval: sy)
      else
        set_args_keys(state: 'no', delay: '', minimum: '', minval: '',
                      reload: '', relval: '', sync: '', syncval: '')
      end
      config_set('interface_hsrp_group', 'preempt', @set_args)
    end

    def default_preempt
      config_get_default('interface_hsrp_group', 'preempt')
    end

    def default_preempt_delay_minimum
      config_get_default('interface_hsrp_group', 'preempt_delay_minimum')
    end

    def default_preempt_delay_reload
      config_get_default('interface_hsrp_group', 'preempt_delay_reload')
    end

    def default_preempt_delay_sync
      config_get_default('interface_hsrp_group', 'preempt_delay_sync')
    end

    # This CLI can take forms like:
    # priority 10
    # priority 50 forwarding-threshold lower 10 upper 49
    def priority_level_get
      hash = {}
      hash[:priority] = default_priority
      hash[:lower] = default_priority_forward_thresh_lower
      hash[:upper] = default_priority_forward_thresh_upper
      arr = config_get('interface_hsrp_group', 'priority_level', @get_args)
      if arr
        hash[:priority] = arr[0].to_i
        hash[:lower] = arr[1].to_i if arr[1]
        hash[:upper] = arr[2].to_i if arr[2]
      end
      hash
    end

    def priority
      priority_level_get[:priority]
    end

    def default_priority
      config_get_default('interface_hsrp_group', 'priority')
    end

    def priority_forward_thresh_lower
      priority_level_get[:lower]
    end

    def default_priority_forward_thresh_lower
      config_get_default('interface_hsrp_group',
                         'priority_forward_thresh_lower')
    end

    def priority_forward_thresh_upper
      priority_level_get[:upper]
    end

    def default_priority_forward_thresh_upper
      config_get_default('interface_hsrp_group',
                         'priority_forward_thresh_upper')
    end

    def priority_level_set(pri, lower, upper)
      if pri && !lower.to_s.empty? && !upper.to_s.empty?
        set_args_keys(state: '', pri: pri,
                      forward: 'forwarding-threshold lower',
                      lval: lower, upper: 'upper', uval: upper)
      elsif pri
        set_args_keys(state: '', pri: pri,
                      forward: '', lval: '', upper: '', uval: '')
      else
        set_args_keys(state: 'no', pri: pri, forward: '', lval: '',
                      upper: '', uval: '')
      end
      config_set('interface_hsrp_group', 'priority_level', @set_args)
    end

    # This CLI can take forms like:
    # timers  1  3
    # timers msec 300  3
    # timers msec 750 msec 2500
    def timers_get
      hash = {}
      hash[:hello] = default_timers_hello
      hash[:mshello] = default_timers_hello_msec
      hash[:hold] = default_timers_hold
      hash[:mshold] = default_timers_hold_msec
      str = config_get('interface_hsrp_group', 'timers', @get_args)
      return hash if str.nil?
      regexp = Regexp.new('(?<msec1>msec)?'\
               ' *(?<he>\d+) *(?<msec2>msec)? *(?<ho>\d+)')
      params = regexp.match(str)
      hash[:mshello] = true if params[:msec1]
      hash[:mshold] = true if params[:msec2]
      hash[:hello] = params[:he].to_i
      hash[:hold] = params[:ho].to_i
      hash
    end

    def timers_hello
      timers_get[:hello]
    end

    def timers_hello_msec
      timers_get[:mshello]
    end

    def default_timers_hello
      config_get_default('interface_hsrp_group', 'timers_hello')
    end

    def default_timers_hello_msec
      config_get_default('interface_hsrp_group', 'timers_hello_msec')
    end

    def timers_hold
      timers_get[:hold]
    end

    def timers_hold_msec
      timers_get[:mshold]
    end

    def default_timers_hold_msec
      config_get_default('interface_hsrp_group', 'timers_hold_msec')
    end

    def default_timers_hold
      config_get_default('interface_hsrp_group', 'timers_hold')
    end

    def timers_set(mshello, hello, mshold, hold)
      if hello && hold
        msechello = mshello ? 'msec' : ''
        msechold = mshold ? 'msec' : ''
        set_args_keys(state: '', mshello: msechello,
                      hello: hello, mshold: msechold, hold: hold)
      else
        set_args_keys(state: 'no', mshello: '', hello: '',
                      mshold: '', hold: '')
      end
      config_set('interface_hsrp_group', 'timers', @set_args)
    end
  end # class
end # module
