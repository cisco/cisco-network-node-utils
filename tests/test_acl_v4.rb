# Copyright (c) 2014-2015 Cisco and/or its affiliates.
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

require_relative 'ciscotest'
require_relative '../lib/cisco_node_utils/acl_v4'

# TestX__CLASS_NAME__X - Minitest for X__CLASS_NAME__X node utility class
class TestAclV4 < CiscoTestCase
  attr_reader :acl_name
  def setup
    # setup runs at the beginning of each test
    super
    @acl_name = "test-foo-1"
    no_ip_access_list_foo
  end

  def teardown
    # teardown runs at the end of each test
    no_ip_access_list_foo
    super
  end

  def no_ip_access_list_foo
    # Turn the feature off for a clean test.
    config('no ip access-list ' + @acl_name)
    config('no ipv6 access-list ' + @acl_name)
  end

  # TESTS

  def test_router_create_acl_v4
    name = @acl_name
    rtr = RouterAcl.new(name, "v4")
    @default_show_command = "show runn | i 'ip access-list #{name}'"
    assert_show_match(pattern: /^ip access-list #{name}$/,
                      msg:     "failed to create acl #{name}")
    rtr.destroy
    refute_show_match(pattern: /^ip access-list #{name}$/,
                      msg:     "failed to destroy acl #{name}")
  end

  def test_router_stats_enable
    name = @acl_name
    rtr = RouterAcl.new(name, "v4")
    rtr.config_stats_enable
    @default_show_command = "show runn | sec 'ip access-list #{name}'"
    assert_show_match(pattern: /statistics per-entry/,
                      msg:     "failed to enable stats")
    rtr.destroy
    refute_show_match(pattern: /^ip access-list #{name}$/,
                      msg:     "failed to destroy acl #{name}")
  end

  def test_router_create_acl_v6
    name = @acl_name
    rtr = RouterAcl.new(name, "v6")
    @default_show_command = "show runn | i 'ipv6 access-list #{name}'"
    assert_show_match(pattern: /^ipv6 access-list #{name}$/,
                      msg:     "failed to create acl #{name}")
    rtr.destroy
    refute_show_match(pattern: /^ipv6 access-list #{name}$/,
                      msg:     "failed to destroy acl #{name}")
  end

  def test_router_stats_enable_v6
    name = @acl_name
    rtr = RouterAcl.new(name, "v6")
    rtr.config_stats_enable
    @default_show_command = "show runn | sec 'ipv6 access-list #{name}'"
    assert_show_match(pattern: /statistics per-entry/,
                      msg:     "failed to enable stats")
    rtr.destroy
    refute_show_match(pattern: /^ipv6 access-list #{name}$/,
                      msg:     "failed to destroy acl #{name}")
  end
end
