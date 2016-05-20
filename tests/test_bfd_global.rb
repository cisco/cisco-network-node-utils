# Copyright (c) 2016 Cisco and/or its affiliates.
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
require_relative '../lib/cisco_node_utils/bfd_global'

include Cisco
# TestBfdGlobal - Minitest for general functionality
# of the BfdGlobal class.
class TestBfdGlobal < CiscoTestCase
  @skip_unless_supported = 'bfd_global'
  # Tests

  def setup
    super
    config 'no feature bfd'
  end

  def teardown
    config 'no feature bfd'
    super
  end

  def test_create_destroy
    assert_empty(BfdGlobal.globals)

    # create
    bg = BfdGlobal.new('default')
    assert_equal('default', bg.name)
    refute_empty(BfdGlobal.globals)

    # destroy
    bg.destroy
    assert_empty(BfdGlobal.globals)
  end

  def test_echo_interface
    bg = BfdGlobal.new('default')
    if validate_property_excluded?('bfd_global', 'echo_interface')
      assert_nil(bg.echo_interface)
      assert_raises(Cisco::UnsupportedError) do
        bg.echo_interface = 10
      end
      return
    end
    config 'interface loopback 10'
    bg.echo_interface = 10
    assert_equal(10, bg.echo_interface)
    bg.echo_interface = bg.default_echo_interface
    assert_equal(bg.default_echo_interface, bg.echo_interface)
    config 'no interface loopback 10'
  end

  def test_fabricpath_vlan
    bg = BfdGlobal.new('default')
    if validate_property_excluded?('bfd_global', 'fabricpath_vlan')
      assert_nil(bg.fabricpath_vlan)
      assert_raises(Cisco::UnsupportedError) do
        bg.fabricpath_vlan = 100
      end
      return
    end
    bg.fabricpath_vlan = 100
    assert_equal(100, bg.fabricpath_vlan)
    bg.fabricpath_vlan = bg.default_fabricpath_vlan
    assert_equal(bg.default_fabricpath_vlan, bg.fabricpath_vlan)
  end

  def test_startup_timer
    bg = BfdGlobal.new('default')
    if validate_property_excluded?('bfd_global', 'startup_timer')
      assert_nil(bg.startup_timer)
      assert_raises(Cisco::UnsupportedError) do
        bg.startup_timer = 25
      end
      return
    end
    bg.startup_timer = 25
    assert_equal(25, bg.startup_timer)
    bg.startup_timer = bg.default_startup_timer
    assert_equal(bg.default_startup_timer, bg.startup_timer)
  end

  def test_echo_rx_interval
    bg = BfdGlobal.new('default')
    if validate_property_excluded?('bfd_global', 'echo_rx_interval')
      assert_nil(bg.echo_rx_interval)
      assert_raises(Cisco::UnsupportedError) do
        bg.echo_rx_interval = 300
      end
      return
    end
    bg.echo_rx_interval = 300
    assert_equal(300, bg.echo_rx_interval)
    bg.echo_rx_interval = bg.default_echo_rx_interval
    assert_equal(bg.default_echo_rx_interval, bg.echo_rx_interval)
    bg.ipv4_echo_rx_interval = 100
    assert_equal(100, bg.ipv4_echo_rx_interval)
    bg.ipv4_echo_rx_interval = bg.default_ipv4_echo_rx_interval
    assert_equal(bg.default_ipv4_echo_rx_interval, bg.ipv4_echo_rx_interval)
    bg.ipv6_echo_rx_interval = 200
    assert_equal(200, bg.ipv6_echo_rx_interval)
    bg.ipv6_echo_rx_interval = bg.default_ipv6_echo_rx_interval
    assert_equal(bg.default_ipv6_echo_rx_interval, bg.ipv6_echo_rx_interval)
  end

  def test_slow_timer
    bg = BfdGlobal.new('default')
    bg.slow_timer = 2000
    assert_equal(2000, bg.slow_timer)
    bg.slow_timer = bg.default_slow_timer
    assert_equal(bg.default_slow_timer, bg.slow_timer)
    bg.ipv4_slow_timer = 10_000
    assert_equal(10_000, bg.ipv4_slow_timer)
    bg.ipv4_slow_timer = bg.default_ipv4_slow_timer
    assert_equal(bg.default_ipv4_slow_timer, bg.ipv4_slow_timer)
    bg.ipv6_slow_timer = 25_000
    assert_equal(25_000, bg.ipv6_slow_timer)
    bg.ipv6_slow_timer = bg.default_ipv6_slow_timer
    assert_equal(bg.default_ipv6_slow_timer, bg.ipv6_slow_timer)
  end

  def test_fabricpath_slow_timer
    bg = BfdGlobal.new('default')
    if validate_property_excluded?('bfd_global', 'fabricpath_slow_timer')
      skip('Test not supported on this platform')
      # assert_nil(bg.fabricpath_slow_timer)
      # assert_raises(Cisco::UnsupportedError) do
      #  bg.fabricpath_slow_timer = 15000
      # end
      return
    end
    bg.fabricpath_slow_timer = 15_000
    assert_equal(15_000, bg.fabricpath_slow_timer)
    bg.fabricpath_slow_timer = bg.default_fabricpath_slow_timer
    assert_equal(bg.default_fabricpath_slow_timer, bg.fabricpath_slow_timer)
  end

  def interval_params_helper(props)
    bg = BfdGlobal.new('default')
    test_hash = {
      interval:   bg.default_interval,
      min_rx:     bg.default_min_rx,
      multiplier: bg.default_multiplier,
    }.merge!(props)
    bg.interval_params_set(test_hash, '')
    bg
  end

  def test_interval_params
    bg = interval_params_helper(interval:   100,
                                min_rx:     100,
                                multiplier: 25)
    assert_equal(100, bg.interval)
    assert_equal(100, bg.min_rx)
    assert_equal(25, bg.multiplier)
    bg = interval_params_helper(interval:   bg.default_interval,
                                min_rx:     bg.default_min_rx,
                                multiplier: bg.default_multiplier)
    assert_equal(bg.default_interval, bg.interval)
    assert_equal(bg.default_min_rx, bg.min_rx)
    assert_equal(bg.default_multiplier, bg.multiplier)
  end

  def ipv4_interval_params_helper(props)
    bg = BfdGlobal.new('default')
    test_hash = {
      ipv4_interval:   bg.default_ipv4_interval,
      ipv4_min_rx:     bg.default_ipv4_min_rx,
      ipv4_multiplier: bg.default_ipv4_multiplier,
    }.merge!(props)
    bg.interval_params_set(test_hash, 'ipv4')
    bg
  end

  def test_ipv4_interval_params
    bg = ipv4_interval_params_helper(ipv4_interval:   200,
                                     ipv4_min_rx:     200,
                                     ipv4_multiplier: 50)
    assert_equal(200, bg.ipv4_interval)
    assert_equal(200, bg.ipv4_min_rx)
    assert_equal(50, bg.ipv4_multiplier)
    bg = ipv4_interval_params_helper(
      ipv4_interval:   bg.default_ipv4_interval,
      ipv4_min_rx:     bg.default_ipv4_min_rx,
      ipv4_multiplier: bg.default_ipv4_multiplier)
    assert_equal(bg.default_ipv4_interval, bg.ipv4_interval)
    assert_equal(bg.default_ipv4_min_rx, bg.ipv4_min_rx)
    assert_equal(bg.default_ipv4_multiplier, bg.ipv4_multiplier)
  end

  def ipv6_interval_params_helper(props)
    bg = BfdGlobal.new('default')
    test_hash = {
      ipv6_interval:   bg.default_ipv6_interval,
      ipv6_min_rx:     bg.default_ipv6_min_rx,
      ipv6_multiplier: bg.default_ipv6_multiplier,
    }.merge!(props)
    bg.interval_params_set(test_hash, 'ipv6')
    bg
  end

  def test_ipv6_interval_params
    bg = ipv6_interval_params_helper(ipv6_interval:   500,
                                     ipv6_min_rx:     500,
                                     ipv6_multiplier: 30)
    assert_equal(500, bg.ipv6_interval)
    assert_equal(500, bg.ipv6_min_rx)
    assert_equal(30, bg.ipv6_multiplier)
    bg = ipv6_interval_params_helper(
      ipv6_interval:   bg.default_ipv6_interval,
      ipv6_min_rx:     bg.default_ipv6_min_rx,
      ipv6_multiplier: bg.default_ipv6_multiplier)
    assert_equal(bg.default_ipv6_interval, bg.ipv6_interval)
    assert_equal(bg.default_ipv6_min_rx, bg.ipv6_min_rx)
    assert_equal(bg.default_ipv6_multiplier, bg.ipv6_multiplier)
  end

  def fabricpath_interval_params_helper(props)
    bg = BfdGlobal.new('default')
    test_hash = {
      fabricpath_interval:   bg.default_fabricpath_interval,
      fabricpath_min_rx:     bg.default_fabricpath_min_rx,
      fabricpath_multiplier: bg.default_fabricpath_multiplier,
    }.merge!(props)
    bg.interval_params_set(test_hash, 'fabricpath')
    bg
  end

  def test_fabricpath_interval_params
    bg = fabricpath_interval_params_helper(fabricpath_interval:   750,
                                           fabricpath_min_rx:     350,
                                           fabricpath_multiplier: 45)
    assert_equal(750, bg.fabricpath_interval)
    assert_equal(350, bg.fabricpath_min_rx)
    assert_equal(45, bg.fabricpath_multiplier)
    bg = fabricpath_interval_params_helper(
      fabricpath_interval:   bg.default_fabricpath_interval,
      fabricpath_min_rx:     bg.default_fabricpath_min_rx,
      fabricpath_multiplier: bg.default_fabricpath_multiplier)
    assert_equal(bg.default_fabricpath_interval, bg.fabricpath_interval)
    assert_equal(bg.default_fabricpath_min_rx, bg.fabricpath_min_rx)
    assert_equal(bg.default_fabricpath_multiplier, bg.fabricpath_multiplier)
  end
end
