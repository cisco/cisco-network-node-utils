# NXAPI implementation of AaaAuthorizationService class
#
# May 2015, Alex Hunsberger
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

module Cisco
  # AaaAuthorizationService - node util class for aaa authorization management
  class AaaAuthorizationService < NodeUtil
    attr_reader :name, :type

    def initialize(type, name, create=true)
      fail TypeError unless name.is_a? String
      fail TypeError unless type.is_a? Symbol
      # only console and default are supported currently
      fail ArgumentError unless %w(console default).include? name
      fail ArgumentError unless
        %i(commands config_commands ssh_certificate ssh_publickey).include? type
      @name = name
      @type = type
      type_str = AaaAuthorizationService.auth_type_sym_to_str(type)

      return unless create

      config_set('aaa_authorization_service', 'method', '', type_str, name)
    end

    def self.services
      servs = {}
      servs_arr = config_get('aaa_authorization_service', 'services')
      unless servs_arr.nil?
        servs_arr.each do |type, name|
          type = auth_type_str_to_sym(type)
          servs[type] ||= {}
          servs[type][name] = AaaAuthorizationService.new(type, name, false)
        end
      end
      servs
    end

    def destroy
      # must specify exact current config string to unconfigure
      m = method
      m_str = m == :unselected ? '' : m.to_s
      g_str = groups.join(' ')
      t_str = AaaAuthorizationService.auth_type_sym_to_str(@type)

      if g_str.empty?
        # cannot remove no groups + local, so do nothing in this case
        unless m == :local
          config_set('aaa_authorization_service', 'method',
                     'no', t_str, @name)
        end
      else
        config_set('aaa_authorization_service', 'groups',
                   'no', t_str, @name, g_str, m_str)
      end
    end

    # groups aren't retrieved via the usual CLI regex memory type because
    # there can be an arbitrary number of groups and specifying a repeating
    # memory regex only captures the last match
    # ex: aaa authorization console group group1 group2 group3 local
    def groups
      # config_get returns the following format:
      # [{"appl_subtype": "console",
      #   "cmd_type": "config-commands",
      #   "methods": "group foo bar local "}], ...
      hsh_arr = config_get('aaa_authorization_service', 'groups')
      fail 'unable to retrieve aaa groups information' if hsh_arr.empty?
      type_s = AaaAuthorizationService.auth_type_sym_to_str(@type)
      hsh = hsh_arr.find do |x|
        x['appl_subtype'] == @name && x['cmd_type'] == type_s
      end
      fail "no aaa info for #{@type},#{@name}" if hsh.nil?
      fail "no aaa info for #{@type},#{@name}. api/feature change?" unless
        hsh.key? 'methods'
      # ex: ["group", "group1", "local"]
      grps = hsh['methods'].strip.split
      # return [] if grps.size == 1
      # remove local, group keywords
      grps -= %w(local group)
      grps
    end

    # default is []
    def default_groups
      config_get_default('aaa_authorization_service', 'groups')
    end

    def method
      t_str = AaaAuthorizationService.auth_type_sym_to_str(@type)
      m = config_get('aaa_authorization_service', 'method', @name, t_str)
      m.nil? ? :unselected : m.to_sym
    end

    # default is :local
    def default_method
      config_get_default('aaa_authorization_service', 'method')
    end

    # groups and method must be set in the same CLI string
    # aaa authorization login <type> <name> /
    #   local | group <group1 [group2, ...]> [local]
    def groups_method_set(grps, m)
      fail TypeError unless grps.is_a? Array
      fail TypeError unless grps.all? { |x| x.is_a? String }
      fail TypeError unless m.is_a? Symbol
      # only the following are supported (unselected = blank)
      fail ArgumentError unless [:local, :unselected].include? m

      # raise "type 'local' not allowed when groups are configured" if
      #  m == :local and not grps.empty?
      m_str = m == :unselected ? '' : m.to_s
      g_str = grps.join(' ')
      t_str = AaaAuthorizationService.auth_type_sym_to_str(@type)

      # config_set depends on whether we're setting groups or not
      if g_str.empty?
        config_set('aaa_authorization_service', 'method',
                   '', t_str, @name)
      else
        config_set('aaa_authorization_service', 'groups',
                   '', t_str, @name, g_str, m_str)
      end
    end

    def self.auth_type_sym_to_str(sym)
      sym.to_s.sub('_', '-')
    end

    def self.auth_type_str_to_sym(str)
      str.sub('-', '_').to_sym
    end
  end
end
