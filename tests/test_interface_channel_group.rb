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

  def test_channel_group
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
