#
# Minitest for TacacsServerGroup class
#
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
require_relative '../lib/cisco_node_utils/tacacs_server_group'

# TestTacacsServerGroup - Minitest for TacacsServerGroup node utility.
class TestTacacsServerGroup < CiscoTestCase
  def setup
    # setup runs at the beginning of each test
    super
    config('no feature tacacs+', 'feature tacacs+',
           'tacacs-server host 8.8.8.8',
           'tacacs-server host 9.9.9.9',
           'tacacs-server host 10.10.10.10',
           'tacacs-server host 11.11.11.11',
           'tacacs-server host 12.12.12.12',
           'tacacs-server host 13.13.13.13')
    no_tacacsserver
  end

  def teardown
    # teardown runs at the end of each test
    config('no feature tacacs+')
    no_tacacsserver
    super
  end

  def no_tacacsserver
    # Turn the feature off for a clean test.
    config('no aaa group server tacacs+ red',
           'no aaa group server tacacs+ blue')
  end

  # TESTS

  def test_create_destroy_single
    id = 'red'
    refute_includes(Cisco::TacacsServerGroup.tacacs_server_groups, id)

    group = Cisco::TacacsServerGroup.new(id, true)
    assert_includes(Cisco::TacacsServerGroup.tacacs_server_groups, id)
    assert_equal(Cisco::TacacsServerGroup.tacacs_server_groups[id], group)

    group.servers = ['8.8.8.8', '9.9.9.9']
    assert_equal(['8.8.8.8', '9.9.9.9'],
                 Cisco::TacacsServerGroup.tacacs_server_groups[id].servers)

    group.servers = ['8.8.8.8', '10.10.10.10']
    assert_equal(['8.8.8.8', '10.10.10.10'],
                 Cisco::TacacsServerGroup.tacacs_server_groups[id].servers)

    group.servers = []
    assert_equal([],
                 Cisco::TacacsServerGroup.tacacs_server_groups[id].servers)

    group.destroy
    refute_includes(Cisco::TacacsServerGroup.tacacs_server_groups, id)
  end

  def test_create_destroy_multiple
    id = 'red'
    id2 = 'blue'
    refute_includes(Cisco::TacacsServerGroup.tacacs_server_groups, id)
    refute_includes(Cisco::TacacsServerGroup.tacacs_server_groups, id2)

    group = Cisco::TacacsServerGroup.new(id, true)
    group2 = Cisco::TacacsServerGroup.new(id2, true)
    assert_includes(Cisco::TacacsServerGroup.tacacs_server_groups, id)
    assert_equal(Cisco::TacacsServerGroup.tacacs_server_groups[id], group)
    assert_includes(Cisco::TacacsServerGroup.tacacs_server_groups, id2)
    assert_equal(Cisco::TacacsServerGroup.tacacs_server_groups[id2], group2)

    group.servers = ['8.8.8.8', '9.9.9.9']
    assert_equal(['8.8.8.8', '9.9.9.9'],
                 Cisco::TacacsServerGroup.tacacs_server_groups[id].servers)
    group2.servers = ['11.11.11.11', '12.12.12.12']
    assert_equal(['11.11.11.11', '12.12.12.12'],
                 Cisco::TacacsServerGroup.tacacs_server_groups[id2].servers)

    group.servers = ['8.8.8.8', '10.10.10.10']
    assert_equal(['8.8.8.8', '10.10.10.10'],
                 Cisco::TacacsServerGroup.tacacs_server_groups[id].servers)
    group2.servers = ['11.11.11.11', '13.13.13.13']
    assert_equal(['11.11.11.11', '13.13.13.13'],
                 Cisco::TacacsServerGroup.tacacs_server_groups[id2].servers)

    group.servers = []
    assert_equal([],
                 Cisco::TacacsServerGroup.tacacs_server_groups[id].servers)
    group2.servers = []
    assert_equal([],
                 Cisco::TacacsServerGroup.tacacs_server_groups[id2].servers)

    group.destroy
    group2.destroy
    refute_includes(Cisco::TacacsServerGroup.tacacs_server_groups, id)
    refute_includes(Cisco::TacacsServerGroup.tacacs_server_groups, id2)
  end
end
