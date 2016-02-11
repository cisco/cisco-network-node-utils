#
# Minitest for RadiusServerGroup class
#
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

require File.expand_path('../ciscotest', __FILE__)
require File.expand_path('../../lib/cisco_node_utils/radius_server_group', \
                         __FILE__)

# TestRadiusServerGroup - Minitest for RadiusServerGroup node utility.
class TestRadiusServerGroup < CiscoTestCase
  def setup
    # setup runs at the beginning of each test
    super
    config('radius-server host 8.8.8.8',
           'radius-server host 9.9.9.9',
           'radius-server host 10.10.10.10',
           'radius-server host 11.11.11.11',
           'radius-server host 12.12.12.12',
           'radius-server host 2005::3',
           'radius-server host 2006::3',
           'radius-server host 2007::3',
           'radius-server host 2008::3')
    no_radiusserver
  end

  def teardown
    # teardown runs at the end of each test
    config('no radius-server host 8.8.8.8',
           'no radius-server host 9.9.9.9',
           'no radius-server host 10.10.10.10',
           'no radius-server host 11.11.11.11',
           'no radius-server host 12.12.12.12',
           'no radius-server host 2005::3',
           'no radius-server host 2006::3',
           'no radius-server host 2007::3',
           'no radius-server host 2008::3')
    no_radiusserver
    super
  end

  def no_radiusserver
    # Turn the feature off for a clean test.
    config('no aaa group server radius red',
           'no aaa group server radius blue')
  end

  # TESTS

  def test_create_destroy_single
    id = 'red'
    refute_includes(Cisco::RadiusServerGroup.radius_server_groups, id)

    group = Cisco::RadiusServerGroup.new(id, true)
    assert_includes(Cisco::RadiusServerGroup.radius_server_groups, id)
    assert_equal(group, Cisco::RadiusServerGroup.radius_server_groups[id])

    group.servers = ['8.8.8.8', '9.9.9.9']
    assert_equal(['8.8.8.8', '9.9.9.9'],
                 Cisco::RadiusServerGroup.radius_server_groups[id].servers)

    group.servers = ['8.8.8.8', '10.10.10.10']
    assert_equal(['8.8.8.8', '10.10.10.10'],
                 Cisco::RadiusServerGroup.radius_server_groups[id].servers)

    group.servers = []
    assert_equal([],
                 Cisco::RadiusServerGroup.radius_server_groups[id].servers)

    group.destroy
    refute_includes(Cisco::RadiusServerGroup.radius_server_groups, id)
  end

  def test_create_destroy_single_ipv6
    id = 'red'
    refute_includes(Cisco::RadiusServerGroup.radius_server_groups, id)

    group = Cisco::RadiusServerGroup.new(id, true)
    assert_includes(Cisco::RadiusServerGroup.radius_server_groups, id)
    assert_equal(group, Cisco::RadiusServerGroup.radius_server_groups[id])

    group.servers = ['2005::3', '2006::3']
    assert_equal(['2005::3', '2006::3'],
                 Cisco::RadiusServerGroup.radius_server_groups[id].servers)

    group.servers = ['2005::3', '2007::3']
    assert_equal(['2005::3', '2007::3'],
                 Cisco::RadiusServerGroup.radius_server_groups[id].servers)

    group.servers = []
    assert_equal([],
                 Cisco::RadiusServerGroup.radius_server_groups[id].servers)

    group.destroy
    refute_includes(Cisco::RadiusServerGroup.radius_server_groups, id)
  end

  def test_create_destroy_multiple
    id = 'red'
    id2 = 'blue'
    refute_includes(Cisco::RadiusServerGroup.radius_server_groups, id)
    refute_includes(Cisco::RadiusServerGroup.radius_server_groups, id2)

    group = Cisco::RadiusServerGroup.new(id, true)
    group2 = Cisco::RadiusServerGroup.new(id2, true)
    assert_includes(Cisco::RadiusServerGroup.radius_server_groups, id)
    assert_equal(group, Cisco::RadiusServerGroup.radius_server_groups[id])
    assert_includes(Cisco::RadiusServerGroup.radius_server_groups, id2)
    assert_equal(group2, Cisco::RadiusServerGroup.radius_server_groups[id2])

    group.servers = ['8.8.8.8', '9.9.9.9']
    assert_equal(['8.8.8.8', '9.9.9.9'],
                 Cisco::RadiusServerGroup.radius_server_groups[id].servers)
    group2.servers = ['11.11.11.11', '12.12.12.12']
    assert_equal(['11.11.11.11', '12.12.12.12'],
                 Cisco::RadiusServerGroup.radius_server_groups[id2].servers)

    group.servers = ['8.8.8.8', '10.10.10.10']
    assert_equal(['8.8.8.8', '10.10.10.10'],
                 Cisco::RadiusServerGroup.radius_server_groups[id].servers)
    group2.servers = ['11.11.11.11', '2008::3']
    assert_equal(['11.11.11.11', '2008::3'],
                 Cisco::RadiusServerGroup.radius_server_groups[id2].servers)

    group.servers = []
    assert_equal([],
                 Cisco::RadiusServerGroup.radius_server_groups[id].servers)
    group2.servers = []
    assert_equal([],
                 Cisco::RadiusServerGroup.radius_server_groups[id2].servers)

    group.destroy
    group2.destroy
    refute_includes(Cisco::RadiusServerGroup.radius_server_groups, id)
    refute_includes(Cisco::RadiusServerGroup.radius_server_groups, id2)
  end
end
