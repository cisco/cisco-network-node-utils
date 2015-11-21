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
require_relative '../lib/cisco_node_utils/ace'

# TestX__CLASS_NAME__X - Minitest for X__CLASS_NAME__X node utility class
class TestAceV4 < CiscoTestCase
  attr_reader :acl_name, :seqno, :afi

  def setup
    # setup runs at the beginning of each test
    super
    @acl_name = 'test-foo-1'
    @seqno = 10
    @afi = 'ip'
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

  def test_router_create_destroy_ipv4_ace_one
    acl = Acl.new(@acl_name, @afi)
    @seqno = 10
    ace = Ace.new(@acl_name, @seqno, @afi)
    @default_show_command = "show runn | sec 'ip access-list #{@acl_name}'"
    action = ace.action = 'permit'
    proto = ace.proto = 'tcp'
    ace.src_addr_format = '7.8.9.6 2.3.4.5'
    ace.src_port_format = 'eq 40'
    ace.dst_addr_format = '1.2.3.4/32'
    ace.dst_port_format = 'neq 20'
    ace.option_format = 'precedence critical'
    ace.config_ace
    assert_show_match(pattern: /\s+#{@seqno} #{action} #{proto}.*$/,
                      msg:     "failed to create ace seqno #{@seqno}")
    ace.destroy
    refute_show_match(pattern: /\s+#{@seqno} #{action} #{proto}.*$/,
                      msg:     "failed to remove ace seqno #{@seqno}")

    @seqno = 20
    ace = Ace.new(@acl_name, @seqno, @afi)
    action = ace.action = 'permit'
    proto = ace.proto = 'udp'
    ace.src_addr_format = 'any'
    ace.dst_addr_format = 'any'
    ace.config_ace
    assert_show_match(pattern: /\s+#{seqno} #{action} #{proto}.*$/,
                      msg:     "failed to create ace seqno #{@seqno}")
    ace.destroy
    refute_show_match(pattern: /\s+#{seqno} #{action} #{proto}.*$/,
                      msg:     "failed to remove ace seqno #{@seqno}")
    acl.destroy
  end
end
