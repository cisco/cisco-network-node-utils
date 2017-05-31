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
    # create
    bg = BfdGlobal.new
    assert_equal(true, Feature.bfd_enabled?)

    # destroy
    bg.destroy
    [:interval,
     :ipv4_interval,
     :ipv6_interval,
     :fabricpath_interval,
     :echo_interface,
     :echo_rx_interval,
     :ipv4_echo_rx_interval,
     :ipv6_echo_rx_interval,
     :fabricpath_vlan,
     :slow_timer,
     :ipv4_slow_timer,
     :ipv6_slow_timer,
     :fabricpath_slow_timer,
     :startup_timer,
    ].each do |prop|
      assert_equal(bg.send("default_#{prop}"), bg.send("#{prop}")) if
        bg.send("#{prop}")
    end
  end

  def test_echo_interface
    bg = BfdGlobal.new
    config 'interface loopback 10'
    default = bg.default_echo_interface
    assert_equal(default, bg.echo_interface)
    bg.echo_interface = 'loopback10'
    assert_equal('loopback10', bg.echo_interface)
    bg.echo_interface = default
    assert_equal(default, bg.echo_interface)
    config 'no interface loopback 10'
  end

  def test_fabricpath_vlan
    bg = BfdGlobal.new
    if validate_property_excluded?('bfd_global', 'fabricpath_vlan')
      assert_nil(bg.fabricpath_vlan)
      assert_raises(Cisco::UnsupportedError) do
        bg.fabricpath_vlan = 100
      end
      return
    end
    assert_equal(bg.default_fabricpath_vlan, bg.fabricpath_vlan)
    bg.fabricpath_vlan = 100
    assert_equal(100, bg.fabricpath_vlan)
    bg.fabricpath_vlan = bg.default_fabricpath_vlan
    assert_equal(bg.default_fabricpath_vlan, bg.fabricpath_vlan)
  end

  def test_startup_timer
    bg = BfdGlobal.new
    if validate_property_excluded?('bfd_global', 'startup_timer')
      assert_nil(bg.startup_timer)
      assert_raises(Cisco::UnsupportedError) do
        bg.startup_timer = 25
      end
      return
    end
    assert_equal(bg.default_startup_timer, bg.startup_timer)
    bg.startup_timer = 25
    assert_equal(25, bg.startup_timer)
    bg.startup_timer = bg.default_startup_timer
    assert_equal(bg.default_startup_timer, bg.startup_timer)
  end

  def test_echo_rx_interval
    bg = BfdGlobal.new
    if validate_property_excluded?('bfd_global', 'echo_rx_interval')
      assert_nil(bg.echo_rx_interval)
      assert_raises(Cisco::UnsupportedError) do
        bg.echo_rx_interval = 300
      end
      return
    end
    assert_equal(bg.default_echo_rx_interval, bg.echo_rx_interval)
    bg.echo_rx_interval = 300
    assert_equal(300, bg.echo_rx_interval)
    bg.echo_rx_interval = bg.default_echo_rx_interval
    assert_equal(bg.default_echo_rx_interval, bg.echo_rx_interval)
  end

  def test_ipv4_echo_rx_interval
    bg = BfdGlobal.new
    if validate_property_excluded?('bfd_global', 'ipv4_echo_rx_interval')
      assert_nil(bg.ipv4_echo_rx_interval)
      assert_raises(Cisco::UnsupportedError) do
        bg.ipv4_echo_rx_interval = 100
      end
      return
    end
    assert_equal(bg.default_ipv4_echo_rx_interval, bg.ipv4_echo_rx_interval)
    bg.ipv4_echo_rx_interval = 100
    assert_equal(100, bg.ipv4_echo_rx_interval)
    bg.ipv4_echo_rx_interval = bg.default_ipv4_echo_rx_interval
    assert_equal(bg.default_ipv4_echo_rx_interval, bg.ipv4_echo_rx_interval)
  end

  def test_ipv6_echo_rx_interval
    bg = BfdGlobal.new
    if validate_property_excluded?('bfd_global', 'ipv6_echo_rx_interval')
      assert_nil(bg.ipv6_echo_rx_interval)
      assert_raises(Cisco::UnsupportedError) do
        bg.ipv6_echo_rx_interval = 100
      end
      return
    end
    assert_equal(bg.default_ipv6_echo_rx_interval, bg.ipv6_echo_rx_interval)
    bg.ipv6_echo_rx_interval = 100
    assert_equal(100, bg.ipv6_echo_rx_interval)
    bg.ipv6_echo_rx_interval = bg.default_ipv6_echo_rx_interval
    assert_equal(bg.default_ipv6_echo_rx_interval, bg.ipv6_echo_rx_interval)
  end

  def test_slow_timer
    bg = BfdGlobal.new
    assert_equal(bg.default_slow_timer, bg.slow_timer)
    bg.slow_timer = 5000
    assert_equal(5000, bg.slow_timer)
    bg.slow_timer = bg.default_slow_timer
    assert_equal(bg.default_slow_timer, bg.slow_timer)
  end

  def test_ipv4_slow_timer
    bg = BfdGlobal.new
    if validate_property_excluded?('bfd_global', 'ipv4_slow_timer')
      assert_nil(bg.ipv4_slow_timer)
      assert_raises(Cisco::UnsupportedError) do
        bg.ipv4_slow_timer = 10_000
      end
      return
    end
    assert_equal(bg.default_ipv4_slow_timer, bg.ipv4_slow_timer)
    bg.ipv4_slow_timer = 10_000
    assert_equal(10_000, bg.ipv4_slow_timer)
    bg.ipv4_slow_timer = bg.default_ipv4_slow_timer
    assert_equal(bg.default_ipv4_slow_timer, bg.ipv4_slow_timer)
  end

  def test_ipv6_slow_timer
    bg = BfdGlobal.new
    if validate_property_excluded?('bfd_global', 'ipv6_slow_timer')
      assert_nil(bg.ipv6_slow_timer)
      assert_raises(Cisco::UnsupportedError) do
        bg.ipv6_slow_timer = 25_000
      end
      return
    end
    assert_equal(bg.default_ipv6_slow_timer, bg.ipv6_slow_timer)
    bg.ipv6_slow_timer = 25_000
    assert_equal(25_000, bg.ipv6_slow_timer)
    bg.ipv6_slow_timer = bg.default_ipv6_slow_timer
    assert_equal(bg.default_ipv6_slow_timer, bg.ipv6_slow_timer)
  end

  def test_fabricpath_slow_timer
    bg = BfdGlobal.new
    if validate_property_excluded?('bfd_global', 'fabricpath_slow_timer')
      assert_nil(bg.fabricpath_slow_timer)
      assert_raises(Cisco::UnsupportedError) do
        bg.fabricpath_slow_timer = 15_000
      end
      return
    end
    assert_equal(bg.default_fabricpath_slow_timer, bg.fabricpath_slow_timer)
    bg.fabricpath_slow_timer = 15_000
    assert_equal(15_000, bg.fabricpath_slow_timer)
    bg.fabricpath_slow_timer = bg.default_fabricpath_slow_timer
    assert_equal(bg.default_fabricpath_slow_timer, bg.fabricpath_slow_timer)
  end

  def test_interval
    bg = BfdGlobal.new
    arr = %w(100 100 25)
    skip_incompat_version?('bfd_global', 'interval')
    assert_equal(bg.default_interval, bg.interval)
    bg.interval = arr
    assert_equal(arr, bg.interval)
    bg.interval = bg.default_interval
    assert_equal(bg.default_interval, bg.interval)
  end

  def test_ipv4_interval
    bg = BfdGlobal.new
    arr = %w(200 200 50)
    if validate_property_excluded?('bfd_global', 'ipv4_interval')
      assert_nil(bg.ipv4_interval)
      assert_raises(Cisco::UnsupportedError) do
        bg.ipv4_interval = arr
      end
      return
    end
    assert_equal(bg.default_ipv4_interval, bg.ipv4_interval)
    bg.ipv4_interval = arr
    assert_equal(arr, bg.ipv4_interval)
    bg.ipv4_interval = bg.default_ipv4_interval
    assert_equal(bg.default_ipv4_interval, bg.ipv4_interval)
  end

  def test_ipv6_interval
    bg = BfdGlobal.new
    arr = %w(500 500 30)
    if validate_property_excluded?('bfd_global', 'ipv6_interval')
      assert_nil(bg.ipv6_interval)
      assert_raises(Cisco::UnsupportedError) do
        bg.ipv6_interval = arr
      end
      return
    end
    assert_equal(bg.default_ipv6_interval, bg.ipv6_interval)
    bg.ipv6_interval = arr
    assert_equal(arr, bg.ipv6_interval)
    bg.ipv6_interval = bg.default_ipv6_interval
    assert_equal(bg.default_ipv6_interval, bg.ipv6_interval)
  end

  def test_fabricpath_interval
    bg = BfdGlobal.new
    arr = %w(750 350 45)
    if validate_property_excluded?('bfd_global', 'fabricpath_interval')
      assert_nil(bg.fabricpath_interval)
      assert_raises(Cisco::UnsupportedError) do
        bg.fabricpath_interval = arr
      end
      return
    end
    assert_equal(bg.default_fabricpath_interval, bg.fabricpath_interval)
    bg.fabricpath_interval = arr
    assert_equal(arr, bg.fabricpath_interval)
    bg.fabricpath_interval = bg.default_fabricpath_interval
    assert_equal(bg.default_fabricpath_interval, bg.fabricpath_interval)
  end
end
