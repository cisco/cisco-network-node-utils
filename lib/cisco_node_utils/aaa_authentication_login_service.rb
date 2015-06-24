#
# NXAPI implementation of AaaAuthenticationLoginService class
#
# May 2015, Alex Hunsberger
#
# Copyright (c) 2015 Cisco and/or its affiliates.
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

require File.join(File.dirname(__FILE__), 'node')

module Cisco
class AaaAuthenticationLoginService
  @@node = Cisco::Node.instance

  attr_reader :name

  def initialize(name, create=true)
    raise TypeError unless name.is_a? String
    # only console and default are supported currently
    raise ArgumentError unless %w(console default).include? name
    @name = name

    # console needs to be explicitly created before it appears in
    # "show run aaa all" but oddly not before it shows up in
    # "show aaa authentication"
    if create
      m = default_method.to_s
      @@node.config_set("aaa_auth_login_service", "method", "", name, m)
    end
  end

  def AaaAuthenticationLoginService.services
    servs = {}
    servs_arr = @@node.config_get("aaa_auth_login_service", "services")
    unless servs_arr.nil?
      servs_arr.each { |s|
        servs[s] = AaaAuthenticationLoginService.new(s, false)
      }
    end
    servs
  end

  def destroy
    # must specify exact current config string to unconfigure
    m = method
    m_str = m == :unselected ? "" : m.to_s
    g_str = groups.join(" ")

    if g_str.empty?
      @@node.config_set("aaa_auth_login_service", "method",
        "no", @name, m_str)
    else
      @@node.config_set("aaa_auth_login_service", "groups",
        "no", @name, g_str, m_str)
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
    hsh_arr = @@node.config_get("aaa_auth_login_service", "groups", @name)
    raise "unable to retrieve aaa groups information" if hsh_arr.nil?
    hsh = hsh_arr.find { |x| x["service"] == @name }
    # this should never happen unless @name is invalid
    raise "no aaa info found for service #{@name}" if hsh.nil?
    raise "no method found for #{@name} - api or feature change?" unless
      hsh.key? "method"
    # ex: ["group", "group1", "local"] or maybe ["none"]
    grps = hsh["method"].strip.split
    return [] if grps.size == 1
    # remove local, none, group keywords
    grps -= %w(none local group)
    grps
  end

  # default is []
  def default_groups
    @@node.config_get_default("aaa_auth_login_service", "groups")
  end

  def method
    m = @@node.config_get("aaa_auth_login_service", "method", @name)
    m.nil? ? :unselected : m.first.to_sym
  end

  # default is :local
  def default_method
    @@node.config_get_default("aaa_auth_login_service", "method")
  end

  # groups and method must be set in the same CLI string
  # aaa authentication login { console | default } /
  #   none | local | group <group1 [group2, ...]> [none]
  def groups_method_set(grps, m)
    raise TypeError unless grps.is_a? Array
    raise TypeError unless m.is_a? Symbol
    # only the following 3 are supported (unselected = blank)
    raise ArgumentError unless [:none, :local, :unselected].include? m

    raise "method 'local' not allowed when groups are configured" if
      m == :local and not grps.empty?
    m_str = m == :unselected ? "" : m.to_s
    g_str = grps.join(" ")

    # different config_set depending on whether we're setting groups or not
    if g_str.empty?
      @@node.config_set("aaa_auth_login_service", "method",
        "", @name, m_str)
    else
      @@node.config_set("aaa_auth_login_service", "groups",
        "", @name, g_str, m_str)
    end
  end
end
end
