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
    @acl_name_v4 = 'test-foo-v4-1'
    @acl_name_v6 = 'test-foo-v6-1'
    @rem_str_v4 = 'this is an ipv4 ace'
    @rem_str_v6 = 'this is an ipv6 ace'
    @seqno = 200
    no_ip_access_list_foo
  end

  def teardown
    # teardown runs at the end of each test
    no_ip_access_list_foo
    super
  end

  def no_ip_access_list_foo
    # Turn the feature off for a clean test
    %w(ipv4 ipv6).each do |afi|
      afi = 'ip' if afi[/ipv4/] # TBD platform-specific
      acl_name = afi[/ipv6/] ? @acl_name_v6 : @acl_name_v4
      config('no ' + afi + ' access-list ' + acl_name)
    end
  end

  # TESTS

  def create_destroy_remark(afi, acl_name)
    rtr = Acl.new(afi, acl_name, @seqno)
    afi = 'ip' if afi[/ipv4/] # TBD platform-specific
    rv = Remark.new(afi, acl_name, @seqno)
    if afi == 'ip'
      rv.remark_str = @rem_str_v4
    else
      rv.remark_str = @rem_str_v6
    end
    rv.config_remark('')
    puts rv.remark_str
    @default_show_command = "show runn | sec '#{afi} access-list #{@acl_name}'"
    assert_show_match(pattern: /\s+#{@seqno} remark #{rv.remark_str}.*$/,
                      msg:     'failed to create new_remark '\
                               "#{rv.remark_str}")
    # puts "I am here"
    rv.destroy
    refute_show_match(pattern: /\s+#{@seqno} remark #{rv.remark_str}.*$/,
                      msg:     "failed to remove remark #{@remark_str}")
    rtr.destroy
  end

  def test_create_destroy_remark
    %w(ipv4 ipv6).each do |afi|
      acl_name = afi[/ipv6/] ? @acl_name_v6 : @acl_name_v4
      create_destroy_remark(afi, acl_name)
    end
  end
end
