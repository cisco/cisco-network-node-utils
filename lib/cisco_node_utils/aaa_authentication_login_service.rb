#
# NXAPI implementation of AaaAuthenticationLoginService class
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
  # NXAPI implementation of AAA Authentication Login Service class
  class AaaAuthenticationLoginService < NodeUtil
    attr_reader :name

    def initialize(name, create=true)
      fail TypeError unless name.is_a? String
      # only console and default are supported currently
      fail ArgumentError unless %w(console default).include? name
      @name = name

      # console needs to be explicitly created before it appears in
      # "show run aaa all" but oddly not before it shows up in
      # "show aaa authentication"
      return unless create
      m = default_method.to_s
      config_set('aaa_auth_login_service', 'method', '', name, m)
    end

    def self.services
      servs = {}
      servs_arr = config_get('aaa_auth_login_service', 'services')
      unless servs_arr.nil?
        servs_arr.each do |s|
          servs[s] = AaaAuthenticationLoginService.new(s, false)
        end
      end
      servs
    end

    def destroy
      # must specify exact current config string to unconfigure
      m = method
      m_str = m == :unselected ? '' : m.to_s
      g_str = groups.join(' ')

      if g_str.empty?
        # cannot remove default local, so do nothing in this case
        unless m == :local && @name == 'default'
          config_set('aaa_auth_login_service', 'method',
                     'no', @name, m_str)
        end
      else
        config_set('aaa_auth_login_service', 'groups',
                   'no', @name, g_str, m_str)
      end
    end

    # groups aren't retrieved via the usual CLI regex memory method because
    # there can be an arbitrary number of groups and specifying a repeating
    # memory regex only captures the last match
    # ex: aaa authentication login default group group1 group2 group3 none
    def groups
      # config_get returns the following format:
      # [{service:"default",method:"group group1 none "},
      #  {service:"console",method:"local "}]
      hsh_arr = config_get('aaa_auth_login_service', 'groups')
      fail 'unable to retrieve aaa groups information' if hsh_arr.empty?
      hsh = hsh_arr.find { |x| x['service'] == @name }
      # this should never happen unless @name is invalid
      fail "no aaa info found for service #{@name}" if hsh.nil?
      fail "no method found for #{@name} - api or feature change?" unless
        hsh.key? 'method'
      # ex: ["group", "group1", "local"] or maybe ["none"]
      grps = hsh['method'].strip.split
      return [] if grps.size == 1
      # remove local, none, group keywords
      grps -= %w(none local group)
      grps
    end

    # default is []
    def default_groups
      config_get_default('aaa_auth_login_service', 'groups')
    end

    def method
      m = config_get('aaa_auth_login_service', 'method', @name)
      m.nil? ? :unselected : m.to_sym
    end

    # default is :local
    def default_method
      config_get_default('aaa_auth_login_service', 'method')
    end

    # groups and method must be set in the same CLI string
    # aaa authentication login { console | default } /
    #   none | local | group <group1 [group2, ...]> [none]
    def groups_method_set(grps, m)
      fail TypeError unless grps.is_a? Array
      fail TypeError unless grps.all? { |x| x.is_a? String }
      fail TypeError unless m.is_a? Symbol
      # only the following 3 are supported (unselected = blank)
      fail ArgumentError unless [:none, :local, :unselected].include? m

      fail "method 'local' not allowed when groups are configured" if
        m == :local && !grps.empty?
      m_str = m == :unselected ? '' : m.to_s
      g_str = grps.join(' ')

      # config_set depends on whether we're setting groups or not
      if g_str.empty?
        config_set('aaa_auth_login_service', 'method',
                   '', @name, m_str)
      else
        config_set('aaa_auth_login_service', 'groups',
                   '', @name, g_str, m_str)
      end
    end
  end
end
