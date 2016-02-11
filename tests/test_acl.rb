# Copyright (c) 2014-2016 Cisco and/or its affiliates.
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
  def setup
    # setup runs at the beginning of each test
    super
    @acl_name_v4 = 'test-foo-v4-1'
    @acl_name_v6 = 'test-foo-v6-1'
    @permit = 'permit-all'
    @deny = 'deny-all'
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
  def create_acl(afi, acl_name)
    rtr = Acl.new(afi, acl_name)
    afi_cli = Acl.afi_cli(afi)

    assert(Acl.acls[afi].key?(acl_name),
           "ACL #{afi_cli} #{acl_name} is not configured")

    @default_show_command =
      "show runn aclmgr | i '#{afi_cli} access-list #{acl_name}'"
    assert_show_match(pattern: /^#{afi_cli} access-list #{acl_name}$/,
                      msg:     "failed to create acl '#{afi_cli} #{acl_name}'")
    rtr.destroy
    refute_show_match(pattern: /^#{afi} access-list #{acl_name}$/,
                      msg:     "failed to destroy acl '#{afi_cli} #{acl_name}")
  end

  def test_create_acl
    %w(ipv4 ipv6).each do |afi|
      acl_name = afi[/ipv6/] ? @acl_name_v6 : @acl_name_v4
      create_acl(afi, acl_name)
    end
  end

  def stats_enable(afi, acl_name)
    rtr = Acl.new(afi, acl_name)
    afi_cli = Acl.afi_cli(afi)

    @default_show_command =
      "show runn aclmgr | sec '#{afi_cli} access-list #{acl_name}'"
    assert_show_match(pattern: /^#{afi_cli} access-list #{acl_name}$/,
                      msg:     "failed to create acl #{acl_name}")

    # set to true
    rtr.stats_per_entry = true
    assert_show_match(pattern: /statistics per-entry/,
                      msg:     'failed to enable stats')

    assert(rtr.stats_per_entry)

    # set to false
    rtr.stats_per_entry = false
    refute_show_match(pattern: /statistics per-entry/,
                      msg:     'failed to disnable stats')
    refute(rtr.stats_per_entry)

    # default getter function
    refute(rtr.default_stats_per_entry)

    rtr.destroy
    refute_show_match(pattern: /^#{afi_cli} access-list #{acl_name}$/,
                      msg:     "failed to destroy acl #{acl_name}")
  end

  def test_stats_enable
    %w(ipv4 ipv6).each do |afi|
      acl_name = afi[/ipv6/] ? @acl_name_v6 : @acl_name_v4
      stats_enable(afi, acl_name)
    end
  end

  def set_fragments(rtr, afi, acl_name, option)
    afi_cli = Acl.afi_cli(afi)
    @default_show_command =
      "show runn aclmgr | sec '#{afi_cli} access-list #{acl_name}'"

    # setter function
    rtr.fragments = option
    assert_show_match(pattern: /fragments #{option}/,
                      msg:     'failed to set fragments #{option} ' + option)

    # getter function
    assert_equal(option, rtr.fragments)
  end

  def unset_fragments(rtr, afi, acl_name)
    afi_cli = Acl.afi_cli(afi)
    @default_show_command =
      "show runn aclmgr | sec '#{afi_cli} access-list #{acl_name}'"

    # setter function
    rtr.fragments = nil
    refute_show_match(pattern: /fragments #{@permit}|fragments #{@deny}/,
                      msg:     'failed to unset set fragments')

    # getter function
    val = rtr.fragments
    assert_nil(val)
  end

  def fragments(afi, acl_name)
    rtr = Acl.new(afi, acl_name)
    afi_cli = Acl.afi_cli(afi)

    @default_show_command =
      "show runn aclmgr | sec '#{afi_cli} access-list #{acl_name}'"
    assert_show_match(pattern: /^#{afi_cli} access-list #{acl_name}$/,
                      msg:     "failed to create acl #{acl_name}")

    # set 'no fragments ...'
    unset_fragments(rtr, afi, acl_name)

    # set 'fragments permit-all' from nothing set
    set_fragments(rtr, afi, acl_name, @permit)

    # set 'no fragments ...'
    unset_fragments(rtr, afi, acl_name)

    # set 'fragments deny-all' from nothing set
    set_fragments(rtr, afi, acl_name, @deny)

    # set 'fragments permit-all' from 'fragments deny-all'
    set_fragments(rtr, afi, acl_name, @permit)

    # set 'fragments deny-all' from 'fragments permit-all'
    set_fragments(rtr, afi, acl_name, @deny)

    # default getter function
    val = rtr.default_stats_per_entry
    refute_equal(val, nil, 'value is not nil')

    rtr.destroy
    refute_show_match(pattern: /^#{afi_cli} access-list #{acl_name}$/,
                      msg:     "failed to destroy acl #{acl_name}")
  end

  def test_fragments
    %w(ipv4 ipv6).each do |afi|
      acl_name = afi[/ipv6/] ? @acl_name_v6 : @acl_name_v4
      fragments(afi, acl_name)
    end
  end
end
