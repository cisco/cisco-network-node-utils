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
require_relative '../lib/cisco_node_utils/acl'

# test client for acl creation and deletion
class TestAcl < CiscoTestCase
  attr_reader :acl_name_v4, :acl_name_v6
  def setup
    # setup runs at the beginning of each test
    super
    @acl_name_v4 = 'test-foo-v4-1'
    @acl_name_v6 = 'test-foo-v6-1'
    no_ip_access_list_foo
  end

  def teardown
    # teardown runs at the end of each test
    no_ip_access_list_foo
    super
  end

  def no_ip_access_list_foo
    # Turn the feature off for a clean test.
    config('no ip access-list ' + @acl_name_v4)
    config('no ipv6 access-list ' + @acl_name_v6)
  end

  # TESTS
  def test_router_create_acl_v4
    name = @acl_name_v4
    rtr = Acl.new(name, 'ip')
    Acl.acls
    @default_show_command = "show runn | i 'ip access-list #{name}'"
    assert_show_match(pattern: /^ip access-list #{name}$/,
                      msg:     "failed to create acl #{name}")
    rtr.destroy
    refute_show_match(pattern: /^ip access-list #{name}$/,
                      msg:     "failed to destroy acl #{name}")
  end

  def test_router_stats_enable
    name = @acl_name_v4
    rtr = Acl.new(name, 'ip')
    rtr.stats_perentry = true
    @default_show_command = "show runn | sec 'ip access-list #{name}'"
    assert_show_match(pattern: /statistics per-entry/,
                      msg:     'failed to enable stats')
    rtr.destroy
    refute_show_match(pattern: /^ip access-list #{name}$/,
                      msg:     "failed to destroy acl #{name}")
  end

  def test_router_create_acl_v6
    name = @acl_name_v6
    rtr = Acl.new(name, 'ipv6')
    @default_show_command = "show runn | i 'ipv6 access-list #{name}'"
    assert_show_match(pattern: /^ipv6 access-list #{name}$/,
                      msg:     "failed to create acl #{name}")
    rtr.destroy
    refute_show_match(pattern: /^ipv6 access-list #{name}$/,
                      msg:     "failed to destroy acl #{name}")
  end

  def test_router_stats_enable_v6
    name = @acl_name_v6
    rtr = Acl.new(name, 'ipv6')
    rtr.stats_perentry = true
    @default_show_command = "show runn | sec 'ipv6 access-list #{name}'"
    assert_show_match(pattern: /statistics per-entry/,
                      msg:     'failed to enable stats')
    rtr.destroy
    refute_show_match(pattern: /^ipv6 access-list #{name}$/,
                      msg:     "failed to destroy acl #{name}")
  end
end
