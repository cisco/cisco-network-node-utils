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
  def setup
    # setup runs at the beginning of each test
    super
    @acl_name_v4 = 'test-foo-v4-1'
    @acl_name_v6 = 'test-foo-v6-1'
    @seqno = 10
    no_access_list_foo
  end

  def teardown
    # teardown runs at the end of each test
    no_access_list_foo
    super
  end

  def no_access_list_foo
    # Remove the test ACLs
    %w(ipv4 ipv6).each do |afi|
      acl_name = afi[/ipv6/] ? @acl_name_v6 : @acl_name_v4
      config('no ' + Acl.afi_cli(afi) + ' access-list ' + acl_name)
    end
  end

  # TESTS
  def test_create_destroy_ace_one
    attr_v4_1 = {
      action:        'permit',
      proto:         'tcp',
      src_addr:      '7.8.9.6 2.3.4.5',
      src_port:      'eq 40',
      dst_addr:      '1.2.3.4/32',
      dst_port:      'neq 20',
      option_format: 'precedence critical',
    }

    attr_v4_2 = {
      action:        'deny',
      proto:         'udp',
      src_addr:      '7.8.9.6/32',
      src_port:      'eq 41',
      dst_addr:      'host 1.2.3.4',
      dst_port:      'neq 20',
      option_format: '',
    }

    attr_v4_3 = {
      remark: 'ipv4 remark'
    }

    attr_v6_1 = {
      action:        'permit',
      proto:         '6',
      src_addr:      'addrgroup fi',
      src_port:      '',
      dst_addr:      '1::7/32',
      dst_port:      '',
      option_format: 'dscp cs2 fragments packet-length eq 30',
    }

    attr_v6_2 = {
      action:        'permit',
      proto:         'udp',
      src_addr:      '1::8/56',
      src_port:      'eq 41',
      dst_addr:      'any',
      dst_port:      '',
      option_format: '',
    }

    attr_v6_3 = {
      remark: 'ipv6 remark'
    }

    props = {
      'ipv4' => [attr_v4_1, attr_v4_2, attr_v4_3],
      'ipv6' => [attr_v6_1, attr_v6_2, attr_v6_3],
    }

    %w(ipv4 ipv6).each do |afi|
      @seqno = 0
      props[afi].each do |item|
        create_destroy_ace(afi, item)
      end
    end
  end

  def create_destroy_ace(afi, entry)
    acl_name = @acl_name_v4 if afi[/(ip|ipv4)$/]
    acl_name = @acl_name_v6 if afi[/ipv6/]
    @seqno += 10

    Acl.new(afi, acl_name)
    ace = Ace.new(afi, acl_name, @seqno)
    ace.ace_set(entry)

    afi_cli = Acl.afi_cli(afi)
    all_aces = Ace.aces
    found = false
    all_aces[acl_name].each do |seqno, _inst|
      next unless seqno.to_i == @seqno.to_i
      found = true
    end

    @default_show_command =
      "show runn aclmgr | sec '#{afi_cli} access-list #{acl_name}'"
    assert(found,
           "#{afi_cli} acl #{acl_name} seqno #{@seqno} is not configured")

    if entry.include?(:action)
      action = "#{entry[:action]} .*"
    else
      action = "remark #{entry[:remark]}"
    end
    assert_show_match(pattern: /\s+#{@seqno} #{action}$/,
                      msg:     "failed to create ace seqno #{@seqno}")
    # remove ace
    ace.ace_set({})
    refute_show_match(pattern: /\s+#{@seqno} #{entry[:action]} .*$/,
                      msg:     "failed to remove ace seqno #{@seqno}")
  end
end
