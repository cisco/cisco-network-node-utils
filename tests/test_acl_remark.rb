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
require_relative '../lib/cisco_node_utils/acl_remark'

# TestX__CLASS_NAME__X - Minitest for X__CLASS_NAME__X node utility class
class TestAclRemark < CiscoTestCase
  attr_reader :acl_name, :seqno, :afi

  def setup
    # setup runs at the beginning of each test
    super
    @acl_name = 'test-foo-1-pradeep1'
    @seqno = 200
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

  def test_router_create_one
    acl = Acl.new(@afi, @acl_name)
    remarkvar = Remark.new(@afi, @acl_name, @seqno)
    remarkvar.remark_str = 'this is pradeepb '
    remarkvar.config_remark('')
    print @seqno 
    #print remarkvar.remark_str.to_s
  
    puts remarkvar.remark_str 
    puts "hi" 
    @default_show_command = "show runn | sec 'ip access-list #{@acl_name}'"
    assert_show_match(pattern: /\s+#{@seqno} remark #{remarkvar.remark_str}.*$/,
                      msg:     "failed to create new_remark #{remarkvar.remark_str}")
    remarkvar.destroy
    refute_show_match(pattern: /\s+#{remarkvar.seqno} remark #{remarkvar.remark_str}.*$/,
                      msg:     "failed to remove remark #{@remark_str}")
    acl.destroy
  end
end
