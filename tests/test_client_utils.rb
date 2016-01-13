# Copyright (c) 2013-2016 Cisco and/or its affiliates.
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

require_relative 'basetest'

require_relative '../lib/cisco_node_utils/client/utils.rb'

# TestClientUtils - Minitest for Client utility functions
class TestClientUtils < Minitest::Test
  def show_run_ospf
    "\
router ospf foo
 vrf red
  log-adjacency-changes
router ospf bar
 log-adjacency-changes
 vrf red
  log-adjacency-changes detail
 vrf blue
!
router ospf baz
 log-adjacency-changes detail"
  end

  def test_find_subconfig
    result = Cisco::Client.find_subconfig(show_run_ospf, /router ospf bar/)
    assert_equal("\
log-adjacency-changes
vrf red
 log-adjacency-changes detail
vrf blue",
                 result)

    assert_nil(Cisco::Client.find_subconfig(result, /vrf blue/))

    assert_equal('log-adjacency-changes detail',
                 Cisco::Client.find_subconfig(result, /vrf red/))

    assert_nil(Cisco::Client.find_subconfig(result, /vrf green/))
  end

  def test_filter_cli
    # Unfiltered (no context / values)
    assert_equal(show_run_ospf,
                 Cisco::Client.filter_cli(cli_output: show_run_ospf))
    # Filtered by context but not by value
    assert_equal("\
log-adjacency-changes
vrf red
 log-adjacency-changes detail
vrf blue",
                 Cisco::Client.filter_cli(cli_output: show_run_ospf,
                                          context:    [/router ospf bar/]))
    # Filtered by value but not by context
    assert_equal(['router ospf foo', 'router ospf bar', 'router ospf baz'],
                 Cisco::Client.filter_cli(cli_output: show_run_ospf,
                                          value:      /router ospf .*/))
    # rubocop:disable Style/WordArray

    # Values with a single match group
    assert_equal(['foo', 'bar', 'baz'],
                 Cisco::Client.filter_cli(cli_output: show_run_ospf,
                                          value:      /router ospf (.*)/))
    # Values with multiple match groups
    assert_equal([['ospf', 'foo'], ['ospf', 'bar'], ['ospf', 'baz']],
                 Cisco::Client.filter_cli(cli_output: show_run_ospf,
                                          value:      /router (\S+) (.*)/))
    # rubocop:enable Style/WordArray

    # Values with a single match group
    # Find an entry in the parent submode, ignoring nested submodes
    assert_equal(
      ['log-adjacency-changes'],
      Cisco::Client.filter_cli(cli_output: show_run_ospf,
                               value:      /^log-adjacency-changes.*$/,
                               context:    [/router ospf bar/]))
    # Find an entry in a nested submode
    assert_equal(
      ['log-adjacency-changes detail'],
      Cisco::Client.filter_cli(cli_output: show_run_ospf,
                               value:      /^log-adjacency-changes.*$/,
                               context:    [/router ospf bar/, /vrf red/]))
    # Submode exists but does not have a match
    assert_nil(
      Cisco::Client.filter_cli(cli_output: show_run_ospf,
                               value:      /^log-adjacency-changes.*$/,
                               context:    [/router ospf bar/, /vrf blue/]))
    # Submode does not exist
    assert_nil(
      Cisco::Client.filter_cli(cli_output: show_run_ospf,
                               value:      /^log-adjacency-changes.*$/,
                               context:    [/router ospf bar/, /vrf green/]))

    # Entry exists in submode only
    assert_nil(
      Cisco::Client.filter_cli(cli_output: show_run_ospf,
                               value:      /^log-adjacency-changes.*$/,
                               context:    [/router ospf foo/]))
  end
end
