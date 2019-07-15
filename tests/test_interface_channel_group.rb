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

require_relative 'ciscotest'
require_relative '../lib/cisco_node_utils/interface_channel_group'

# TestInterface - Minitest for general functionality of the Interface class.
class TestInterfaceChanGrp < CiscoTestCase
  @@clean = false # rubocop:disable Style/ClassVars
  def setup
    super
    @intf = InterfaceChannelGroup.new(interfaces[1])

    # Only pre-clean interface on initial setup
    interface_cleanup(@intf.name) unless @@clean
    @@clean = true # rubocop:disable Style/ClassVars
  end

  def teardown
    interface_cleanup(@intf.name)
  end

  # Test InterfaceChannelGroup.interfaces class method api
  def test_interfaces_api
    intf = interfaces[0]
    intf2 = interfaces[1]

    # Verify single_intf usage
    one = InterfaceChannelGroup.interfaces(intf)
    assert_equal(one.keys.length, 1,
                 'Invalid number of keys returned, should be 1')
    assert_equal(one[intf].get_args[:show_name], intf,
                 ':show_name should be intf name when single_intf param specified')

    # Verify 'all' interfaces
    all = InterfaceChannelGroup.interfaces
    assert_operator(all.keys.length, :>, 1,
                    'Invalid number of keys returned, should exceed 1')
    assert_empty(all[intf2].get_args[:show_name],
                 ':show_name should be empty string when single_intf param is nil')
  end

  def test_channel_group
    skip if platform == :nexus
    i = @intf
    group = 200
    i.channel_group = group
    assert_equal(group, i.channel_group)

    group = 201
    i.channel_group = group
    assert_equal(group, i.channel_group)

    group = i.default_channel_group
    i.channel_group = group
    assert_equal(group, i.channel_group)
  rescue Cisco::UnsupportedError => e
    # Some platforms only support channel-group with certain software versions
    skip(e.to_s)
  end

  def test_channel_group_mode
    skip if platform == :ios_xr
    i = @intf
    group = 55

    # Default Case: group = mode = false
    refute(i.channel_group)
    refute(i.channel_group_mode)

    # group = 55, mode = on
    i.channel_group_mode_set(group)
    assert_equal(group, i.channel_group)
    assert_equal(i.default_channel_group_mode, i.channel_group_mode)

    # group = 55, mode = active
    i.channel_group_mode_set(group, 'active')
    assert_equal(group, i.channel_group)
    assert_equal('active', i.channel_group_mode)

    # group = 55, mode = passive
    i.channel_group_mode_set(group, 'passive')
    assert_equal(group, i.channel_group)
    assert_equal('passive', i.channel_group_mode)

    # group = 55, mode = on
    i.channel_group_mode_set(group, 'on')
    assert_equal(group, i.channel_group)
    assert_equal(i.default_channel_group_mode, i.channel_group_mode)

    # group = 66, mode = active
    group = 66
    i.channel_group_mode_set(group, 'active')
    assert_equal(group, i.channel_group)
    assert_equal('active', i.channel_group_mode)

    # group = 66, mode = on
    i.channel_group_mode_set(group)
    assert_equal(group, i.channel_group)
    assert_equal(i.default_channel_group_mode, i.channel_group_mode)

    # Default Case: group = mode = false
    i.channel_group_mode_set(i.default_channel_group)
    refute(i.channel_group)
    refute(i.channel_group_mode)
  end

  def test_description
    i = @intf
    desc = 'test desc'
    i.description = desc
    assert_equal(desc, i.description)

    desc = 'test desc changed'
    i.description = desc
    assert_equal(desc, i.description)

    desc = i.default_description
    i.description = desc
    assert_equal(desc, i.description)
  end

  def test_shutdown
    i = @intf
    i.shutdown = true
    assert(i.shutdown)
    i.shutdown = false
    refute(i.shutdown)

    i.shutdown = i.default_shutdown
    assert_equal(i.default_shutdown, i.shutdown)
  end
end
