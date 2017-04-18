# January 2016, Chris Van Heuveln
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
require_relative 'feature'

# Add some interface-specific constants to the Cisco namespace
module Cisco
  # Interface - node utility class for general interface config management
  class InterfaceChannelGroup < NodeUtil
    attr_reader :name

    def initialize(name)
      validate_args(name)
    end

    def to_s
      "interface_channel_group #{name}"
    end

    def self.interfaces
      hash = {}
      all = config_get('interface_channel_group', 'all_interfaces')
      return hash if all.nil?

      all.each do |id|
        id = id.downcase
        hash[id] = InterfaceChannelGroup.new(id)
      end
      hash
    end

    def validate_args(name)
      fail TypeError unless name.is_a?(String)
      fail ArgumentError unless name.length > 0
      fail "channel_group is not supported on #{name}" unless
        name[/Ethernet/i]
      @name = name.downcase
      set_args_keys
    end

    def set_args_keys(hash={}) # rubocop:disable Style/AccessorMethodName
      @get_args = { name: @name }
      @set_args = @get_args.merge!(hash) unless hash.empty?
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    def channel_group_mode
      match = config_get('interface_channel_group', 'channel_group', @get_args)
      return match unless match
      mode = match[1].nil? ? default_channel_group_mode : match[1]
      mode
    end

    def channel_group_mode_set(group, mode=false)
      cgroup = channel_group
      set_args_keys(state: 'no', group: cgroup, force: '', mode: '', val: '')
      config_set('interface_channel_group', 'channel_group', @set_args) if
        cgroup
      return unless group
      mode = false if mode && mode.to_str == 'on'
      if mode
        Cisco::Feature.lacp_enable
        set_args_keys(state: '', group: group, force: 'force',
                      mode: 'mode', val: mode)
        config_set('interface_channel_group', 'channel_group', @set_args)
      else
        set_args_keys(state: '', group: group, force: 'force',
                      mode: '', val: '')
        config_set('interface_channel_group', 'channel_group', @set_args)
      end
    end

    def channel_group
      match = config_get('interface_channel_group', 'channel_group', @get_args)
      return match unless match
      match[0].to_i
    end

    def default_channel_group
      config_get_default('interface_channel_group', 'channel_group')
    end

    def default_channel_group_mode
      config_get_default('interface_channel_group', 'channel_group_mode')
    end

    # ----------------------------
    def description
      config_get('interface_channel_group', 'description', @get_args)
    end

    def description=(desc)
      state = desc.strip.empty? ? 'no' : ''
      config_set('interface_channel_group', 'description',
                 set_args_keys(state: state, desc: desc))
    end

    def default_description
      config_get_default('interface_channel_group', 'description')
    end

    # ----------------------------
    def shutdown
      config_get('interface_channel_group', 'shutdown', @get_args)
    end

    def shutdown=(state)
      config_set('interface_channel_group', 'shutdown',
                 set_args_keys(state: state ? '' : 'no'))
    end

    def default_shutdown
      config_get_default('interface_channel_group', 'shutdown')
    end
  end  # Class
end    # Module
