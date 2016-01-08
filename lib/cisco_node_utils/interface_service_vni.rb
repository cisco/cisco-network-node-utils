# December 2015, Chris Van Heuveln
#
# Copyright (c) 2015-2016 Cisco and/or its affiliates.
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
require_relative 'vni'

module Cisco
  # InterfaceServiceVni - node utility class for Service VNI Instance commands
  class InterfaceServiceVni < NodeUtil
    attr_reader :name

    def initialize(intf, sid, instantiate=true)
      @name = intf.to_s.downcase
      @sid = sid.to_s
      fail ArgumentError if @name.empty? || @sid.empty?
      set_args_keys_default
      create if instantiate
    end

    def self.svc_vni_ids
      hash = {}
      intf_list = config_get('interface', 'all_interfaces')
      return hash if intf_list.nil?

      intf_list.each do |intf|
        intf.downcase!
        svc_ids = config_get('interface_service_vni', 'all_service_vni_ids',
                             name: intf)
        next if svc_ids.nil?
        hash[intf] = {}
        svc_ids.each do |sid|
          hash[intf][sid] = InterfaceServiceVni.new(intf, sid, false)
        end
      end
      hash
    end

    def create
      Vni.feature_vni_enable unless Vni.feature_vni_enabled
      @set_args[:state] = ''
      config_set('interface_service_vni', 'create_destroy', @set_args)
    end

    def destroy
      @set_args[:state] = 'no'
      config_set('interface_service_vni', 'create_destroy', @set_args)
    end

    def set_args_keys_default
      keys = { name: @name, sid: @sid }
      @get_args = @set_args = keys
    end

    # rubocop:disable Style/AccessorMethodName
    def set_args_keys(hash={})
      set_args_keys_default
      @set_args = @get_args.merge!(hash) unless hash.empty?
    end
    # rubocop:enable Style/AccessorMethodNamefor

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    #
    # encapsulation_profile_vni
    #
    #   cli: service instance 1 vni
    #          encapsulation profile vni_500_5000 default
    #  type: 'vni_500_5000'
    def encapsulation_profile_vni
      config_get('interface_service_vni', 'encapsulation_profile_vni',
                 @get_args)
    end

    def encapsulation_profile_vni=(profile)
      Vni.feature_vni_enable unless Vni.feature_vni_enabled
      state = profile.empty? ? 'no' : ''
      current = encapsulation_profile_vni

      if state[/no/]
        config_set('interface_service_vni', 'encapsulation_profile_vni',
                   set_args_keys(state: state, profile: current)) unless
          current.empty?
      else
        # Remove current profile before adding a new one
        config_set('interface_service_vni', 'encapsulation_profile_vni',
                   set_args_keys(state: 'no', profile: current)) unless
          current.empty?
        config_set('interface_service_vni', 'encapsulation_profile_vni',
                   set_args_keys(state: state, profile: profile))
      end
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def default_encapsulation_profile_vni
      config_get_default('interface_service_vni', 'encapsulation_profile_vni')
    end

    #
    # shutdown
    #
    def shutdown
      config_get('interface_service_vni', 'shutdown', @get_args)
    end

    def shutdown=(state)
      config_set('interface_service_vni', 'shutdown',
                 set_args_keys(state: state ? '' : 'no'))
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def default_shutdown
      config_get_default('interface_service_vni', 'shutdown')
    end
  end  # Class
end    # Module
