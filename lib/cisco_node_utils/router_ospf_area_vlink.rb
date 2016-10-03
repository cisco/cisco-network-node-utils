#
# NXAPI implementation of Router OSPF Area Virtual-link class
#
# June 2016, Sai Chintalapudi
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
require_relative 'router_ospf_vrf'

module Cisco
  # node_utils class for ospf_area_vlink
  class RouterOspfAreaVirtualLink < NodeUtil
    attr_reader :router, :vrf, :area_id, :vl

    def initialize(ospf_router, vrf_name, area_id, virtual_link,
                   instantiate=true)
      fail TypeError unless ospf_router.is_a?(String)
      fail TypeError unless vrf_name.is_a?(String)
      fail ArgumentError unless ospf_router.length > 0
      fail ArgumentError unless vrf_name.length > 0
      @area_id = area_id.to_s
      fail ArgumentError if @area_id.empty?
      fail ArgumentError unless virtual_link.length > 0

      # Convert to dot-notation
      @router = ospf_router
      @vrf = vrf_name
      @area_id = IPAddr.new(area_id.to_i, Socket::AF_INET) unless @area_id[/\./]
      @vl = virtual_link

      set_args_keys_default
      create if instantiate
    end

    def self.virtual_links
      hash = {}
      RouterOspf.routers.each do |name, _obj|
        # get all virtual_links under default vrf
        links = config_get('ospf_area_vlink', 'virtual_links', name: name)
        unless links.nil?
          hash[name] = {}
          hash[name]['default'] = {}
          links.each do |area, vl|
            hash[name]['default'][area] ||= {}
            hash[name]['default'][area][vl] =
              RouterOspfAreaVirtualLink.new(name, 'default', area, vl, false)
          end
        end
        vrf_ids = config_get('ospf', 'vrf', name: name)
        next if vrf_ids.nil?
        vrf_ids.each do |vrf|
          # get all virtual_links under each vrf
          links = config_get('ospf_area_vlink', 'virtual_links',
                             name: name, vrf: vrf)
          next if links.nil?
          hash[name] ||= {}
          hash[name][vrf] = {}
          links.each do |area, vl|
            hash[name][vrf][area] ||= {}
            hash[name][vrf][area][vl] =
              RouterOspfAreaVirtualLink.new(name, vrf, area, vl, false)
          end
        end
      end
      hash
    end

    # Helper method to delete @set_args hash keys
    def set_args_keys_default
      @set_args = { name: @router, area: @area_id, vl: @vl }
      @set_args[:vrf] = @vrf unless @vrf == 'default'
      @get_args = @set_args
    end

    # rubocop:disable Style/AccessorMethodName
    def set_args_keys(hash={})
      set_args_keys_default
      @set_args = @get_args.merge!(hash) unless hash.empty?
    end

    # Create one router ospf area virtual-link instance
    def create
      RouterOspfVrf.new(@router, @vrf)
      set_args_keys(state: '')
      config_set('ospf_area_vlink', 'virtual_links', @set_args)
    end

    def destroy
      return unless Feature.ospf_enabled?
      set_args_keys(state: 'no')
      config_set('ospf_area_vlink', 'virtual_links', @set_args)
    end

    def ==(other)
      (ospf_router == other.ospf_router) &&
        (vrf_name == other.vrf_name) && (area_id == other.area_id) &&
        (vl == other.vl)
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    # CLI can be either of the following or none
    # authentication
    # authentication message-digest
    # authentication null
    def authentication
      auth = config_get('ospf_area_vlink', 'authentication', @get_args)
      return default_authentication unless auth
      if auth.include?('message-digest')
        return 'md5'
      elsif auth.include?('null')
        return 'null'
      else
        return 'cleartext'
      end
    end

    def authentication=(val)
      state = val ? '' : 'no'
      if val.to_s == 'md5'
        auth = 'message-digest'
      elsif val.to_s == 'null'
        auth = 'null'
      else
        auth = ''
      end
      set_args_keys(state: state, auth: auth)
      config_set('ospf_area_vlink', 'authentication', @set_args)
    end

    def default_authentication
      config_get_default('ospf_area_vlink', 'authentication')
    end

    def auth_key_chain
      config_get('ospf_area_vlink', 'auth_key_chain', @get_args)
    end

    def auth_key_chain=(val)
      state = val ? '' : 'no'
      id = val ? val : ''
      set_args_keys(state: state, key_id: id)
      config_set('ospf_area_vlink', 'auth_key_chain', @set_args)
    end

    def default_auth_key_chain
      config_get_default('ospf_area_vlink', 'auth_key_chain')
    end

    def authentication_key_encryption_type
      Encryption.cli_to_symbol(
        config_get('ospf_area_vlink', 'authentication_key_enc_type', @get_args))
    end

    def default_authentication_key_encryption_type
      Encryption.cli_to_symbol(
        config_get_default('ospf_area_vlink', 'authentication_key_enc_type'))
    end

    def authentication_key_password
      config_get('ospf_area_vlink', 'authentication_key_password', @get_args)
    end

    def default_authentication_key_password
      config_get_default('ospf_area_vlink', 'authentication_key_password')
    end

    # example CLI:
    # authentication-key 3 3109a60f51374a0d
    # To remove the authentication-key altogether,
    # set the password to empty string
    def authentication_key_set(enctype, pw)
      state = pw.empty? ? 'no' : ''
      enctype = pw.empty? ? '' : Encryption.symbol_to_cli(enctype)
      set_args_keys(state: state, enctype: enctype, password: pw)
      config_set('ospf_area_vlink', 'authentication_key_set', @set_args)
    end

    def message_digest_algorithm_type
      config_get('ospf_area_vlink', 'message_digest_key_alg_type',
                 @get_args).to_sym
    end

    def default_message_digest_algorithm_type
      config_get_default('ospf_area_vlink',
                         'message_digest_key_alg_type').to_sym
    end

    def message_digest_encryption_type
      Encryption.cli_to_symbol(
        config_get('ospf_area_vlink', 'message_digest_key_enc_type', @get_args))
    end

    def default_message_digest_encryption_type
      Encryption.cli_to_symbol(
        config_get_default('ospf_area_vlink', 'message_digest_key_enc_type'))
    end

    def message_digest_key_id
      config_get('ospf_area_vlink', 'message_digest_key_id', @get_args)
    end

    def default_message_digest_key_id
      config_get_default('ospf_area_vlink', 'message_digest_key_id')
    end

    def message_digest_password
      config_get('ospf_area_vlink', 'message_digest_key_password', @get_args)
    end

    def default_message_digest_password
      config_get_default('ospf_area_vlink', 'message_digest_key_password')
    end

    # example CLI:
    # message-digest-key 39 md5 7 046E1803362E595C260E0B240619050A2D
    # To remove the message-digest-key altogether,
    # set the password to empty string
    def message_digest_key_set(keyid, algtype, enctype, pw)
      return if pw.empty? && message_digest_password.empty?
      # To remove the configuration, the entire previous
      # configuration must be given with 'no' cmd
      state = pw.empty? ? 'no' : ''
      algtype = pw.empty? ? message_digest_algorithm_type : algtype.to_s
      if pw.empty?
        enctype = Encryption.symbol_to_cli(
          message_digest_encryption_type.to_sym)
      else
        enctype = Encryption.symbol_to_cli(enctype)
      end
      keyid = pw.empty? ? message_digest_key_id : keyid
      pw = pw.empty? ? message_digest_password : pw
      set_args_keys(state: state, keyid: keyid, algtype: algtype,
                    enctype: enctype, password: pw)
      config_set('ospf_area_vlink', 'message_digest_key_set', @set_args)
    end

    def dead_interval
      config_get('ospf_area_vlink', 'dead_interval', @get_args)
    end

    def dead_interval=(val)
      state = val == default_dead_interval ? 'no' : ''
      interval = val == default_dead_interval ? '' : val
      set_args_keys(state: state, interval: interval)
      config_set('ospf_area_vlink', 'dead_interval', @set_args)
    end

    def default_dead_interval
      config_get_default('ospf_area_vlink', 'dead_interval')
    end

    def hello_interval
      config_get('ospf_area_vlink', 'hello_interval', @get_args)
    end

    def hello_interval=(val)
      state = val == default_hello_interval ? 'no' : ''
      interval = val == default_hello_interval ? '' : val
      set_args_keys(state: state, interval: interval)
      config_set('ospf_area_vlink', 'hello_interval', @set_args)
    end

    def default_hello_interval
      config_get_default('ospf_area_vlink', 'hello_interval')
    end

    def retransmit_interval
      config_get('ospf_area_vlink', 'retransmit_interval', @get_args)
    end

    def retransmit_interval=(val)
      state = val == default_retransmit_interval ? 'no' : ''
      interval = val == default_retransmit_interval ? '' : val
      set_args_keys(state: state, interval: interval)
      config_set('ospf_area_vlink', 'retransmit_interval', @set_args)
    end

    def default_retransmit_interval
      config_get_default('ospf_area_vlink', 'retransmit_interval')
    end

    def transmit_delay
      config_get('ospf_area_vlink', 'transmit_delay', @get_args)
    end

    def transmit_delay=(val)
      state = val == default_transmit_delay ? 'no' : ''
      delay = val == default_transmit_delay ? '' : val
      set_args_keys(state: state, delay: delay)
      config_set('ospf_area_vlink', 'transmit_delay', @set_args)
    end

    def default_transmit_delay
      config_get_default('ospf_area_vlink', 'transmit_delay')
    end
  end # class
end # module
