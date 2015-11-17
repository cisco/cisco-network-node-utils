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
require_relative '../lib/cisco_node_utils/ace_v4'

# TestX__CLASS_NAME__X - Minitest for X__CLASS_NAME__X node utility class
class TestAceV4 < CiscoTestCase
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
  end

  # TESTS

  def test_router_create_one
    name = @acl_name
    seqno = 10
    action = "permit"
    proto = "tcp"
    v4_src_addr_format = "1.2.3.4/32"
    v4_dst_addr_format = "1.2.3.4 2.3.4.5"
    v4_src_port_format = "eq 60"
    v4_dst_port_format = "neq 45"
    ace_10 = RouterAce.new(name, seqno, action, proto, v4_src_addr_format,
                           v4_dst_addr_format, v4_src_port_format, 
                           v4_dst_port_format)
    @default_show_command = "show runn | sec 'ip access-list #{name}'"
    assert_show_match(pattern: /\s+#{seqno} #{action}/,
                      msg:     "failed to create acl #{name}")
    ace_10.destroy
    refute_show_match(pattern: /\s+#{seqno} #{action}/,
                      msg:     "failed to create acl #{name}")
  end
end
