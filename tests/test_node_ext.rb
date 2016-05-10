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

require_relative 'ciscotest'

# TestNodeExt - Minitest for abstracted Node APIs
class TestNodeExt < CiscoTestCase
  def setup
    super
    @chassis = (platform == :nexus) ? 'Chassis' : 'Rack 0'
    @domain = (platform == :nexus) ? 'ip domain-name' : 'domain name'
  end

  def assert_output_check(command: nil, pattern: nil, msg: nil, check: nil)
    command += ' | no-more' if platform == :nexus
    md = assert_show_match(command: command, pattern: pattern, msg: msg)
    assert_equal(md[1], check, msg)
  end

  def test_config_get
    result = node.config_get('show_version', 'system_image')
    assert_equal(result, node.system)
  end

  def test_config_get_regexp_tokens
    node.client.set(context: ['interface loopback0'], values: ['shutdown'])
    node.client.set(values: ['interface loopback1', 'no shutdown'])

    result = node.config_get('interface', 'shutdown', name: 'loopback1')
    refute(result)
  end

  def test_config_get_invalid
    assert_raises IndexError do # no entry
      node.config_get('foobar', 'name')
    end
    assert_raises IndexError do # entry but no config_get
      node.config_get('show_system', 'resources')
    end
  end

  def test_config_get_default
    result = node.config_get_default('bgp', 'graceful_restart_timers_restart')
    assert_equal(120, result)
  end

  def test_config_get_default_invalid
    assert_raises IndexError do # no name entry
      node.config_get_default('show_version', 'foobar')
    end
    assert_raises IndexError do # no feature entry
      node.config_get_default('foobar', 'name')
    end
    assert_raises IndexError do # no default_value defined
      node.config_get_default('show_version', 'version')
    end
  end

  def test_config_set
    node.config_set('interface', 'create', name: 'loopback122')
    run = node.client.get(command: 'show run | inc interface')
    val = Client.filter_cli(cli_output: run, value: /interface loopback122/i)
    assert_match(/interface loopback122/i, val[0])

    node.config_set('interface', 'destroy', name: 'loopback122')
    run = node.client.get(command: 'show run | inc interface')
    val = Client.filter_cli(cli_output: run, value: /interface loopback122/i)
    assert_nil(val)
  end

  def test_config_set_invalid
    assert_raises IndexError do
      node.config_set('foobar', 'name')
    end
    assert_raises(IndexError, Cisco::UnsupportedError) do
      # feature exists but no config_set
      node.config_set('show_version', 'system_image')
    end
    # TODO: none of the supported classes on IOS XR use printf-style args
    if platform == :nexus # rubocop:disable Style/GuardClause
      assert_raises ArgumentError do # not enough args
        node.config_set('vtp', 'domain')
      end
      assert_raises ArgumentError do # too many args
        node.config_set('vtp', 'domain', 'example.com', 'baz')
      end
    end
  end

  def test_cli_caching
    # don't use config() here because we are testing caching and flushing
    @device.cmd('conf t')
    @device.cmd("#{@domain} minitest")
    @device.cmd('commit') if platform == :ios_xr
    @device.cmd('end')
    dom1 = node.domain_name
    @device.cmd('conf t')
    @device.cmd("no #{@domain} minitest")
    @device.cmd('commit') if platform == :ios_xr
    @device.cmd('end')
    dom2 = node.domain_name
    assert_equal(dom1, dom2) # cached output was used for dom2

    node.cache_flush
    dom3 = node.domain_name
    refute_equal(dom1, dom3)
  end

  def test_get_product_description
    product_description = node.product_description

    command = node.cmd_ref.lookup('show_version', 'description').get_command

    # Hardware
    #   cisco Nexus9000 C9396PX Chassis
    #
    # Other variants for the line of interest:
    #   cisco Nexus9000 C9504 (4 Slot) Chassis ("Supervisor Module")
    #                                          ^-module_id-ignore!-^
    #   cisco Nexus3000 C3132Q Chassis
    #   cisco N3K-C3048TP-1GE
    pattern = /Hardware\n  cisco (([^(\n]+|\(\d+ Slot\))+\w+)/ if
      platform[/nexus/]
    pattern = /DESCR: "(.*)"/ if platform[/ios_xr/]

    assert_output_check(command: command,
                        pattern: pattern,
                        check:   product_description,
                        msg:     'Error, Product description does not match')
  end

  def test_get_product_id
    assert_output_check(command: 'show inventory',
                        pattern: /NAME: \"#{@chassis}\".*\nPID: (\S+)/,
                        check:   node.product_id,
                        msg:     'Error, Product id does not match')
  end

  def test_get_product_version_id
    assert_output_check(command: 'show inventory',
                        pattern: /NAME: \"#{@chassis}\".*\n.*VID: (\w+)/,
                        check:   node.product_version_id,
                        msg:     'Error, Version id does not match')
  end

  def test_get_product_serial_number
    assert_output_check(command: 'show inventory',
                        pattern: /NAME: \"#{@chassis}\".*\n.*SN: ([-\w]+)/,
                        check:   node.product_serial_number,
                        msg:     'Error, Serial number does not match')
  end

  def test_get_os
    assert_output_check(command: 'show version',
                        pattern: /\n(Cisco.*Software)/,
                        check:   node.os,
                        msg:     'Error, OS version does not match')
  end

  def test_get_os_version
    # /N(5|6|7)/
    #   system:    version 7.3(0)D1(1) [build 7.3(0)D1(1)]
    # /N(3|8|9)/
    #   NXOS: version 7.0(3)I3(1) [build 7.0(3)I3(1)]

    pattern = /(?:system|NXOS):\s+version (.*)\n/ if platform[/nexus/]
    pattern = /IOS XR.*Version (.*)$/ if platform[/ios_xr/]

    assert_output_check(command: 'show version',
                        pattern: pattern,
                        check:   node.os_version,
                        msg:     'Error, OS version does not match')
  end

  def test_get_host_name_when_not_set
    if platform == :nexus
      s = @device.cmd('show running-config all | no-more')
    else
      s = @device.cmd('show running-config all')
    end
    pattern = /.*\nhostname (\S+)/
    md = pattern.match(s)
    if md
      configured_name = md[1]
      switchname = false
    else
      # No hostname configured. Lets check if we have switchname instead.
      pattern = /.*\nswitchname (\S+)/
      md = pattern.match(s)
      if md
        configured_name = md[1]
        switchname = true
      else
        configured_name = nil
      end
    end

    switchname ? config('no switchname') : config('no hostname')

    name = node.host_name
    if platform == :nexus
      assert_equal('switch', name)
    else
      assert_equal('ios', name)
    end

    return unless configured_name
    config("hostname #{configured_name}") if switchname == false
    config("switchname #{configured_name}") if switchname == true
  end

  def test_get_host_name_when_set
    if platform == :nexus
      s = @device.cmd('show running-config all | no-more')
    else
      s = @device.cmd('show running-config all')
    end
    pattern = /.*\nhostname (\S+)/
    md = pattern.match(s)
    if md
      configured_name = md[1]
      switchname = false
    else
      # No hostname configured. Lets check if we have switchname instead.
      pattern = /.*\nswitchname (\S+)/
      md = pattern.match(s)
      if md
        configured_name = md[1]
        switchname = true
      else
        configured_name = nil
        switchname = false
      end
    end

    switchname ? config('switchname xyz') : config('hostname xyz')

    host_name = node.host_name
    assert_equal('xyz', host_name)

    if configured_name
      config("hostname #{configured_name}") if switchname == false
      config("switchname #{configured_name}") if switchname == true
    else
      switchname ? config('no switchname') : config('no hostname')
    end
  end

  def test_get_domain_name_when_not_set
    # Test with default vrf only
    s = @device.cmd("show running-config | incl '^#{@domain}'")
    pattern = /^#{@domain} (\S+)/
    md = pattern.match(s)
    if md
      configured_domain_name = md[1]
    else
      configured_domain_name = nil
    end

    config("no #{@domain} #{configured_domain_name}") unless
      configured_domain_name.nil?

    domain_name = node.domain_name
    assert_equal('', domain_name)

    if configured_domain_name
      config("#{@domain} #{configured_domain_name}")
    else
      config("no #{@domain} abc.com")
    end
  end

  def test_get_domain_name_when_set
    s = @device.cmd('show running-config | no-more')
    pattern = /.*\n#{@domain} (\S+)/
    md = pattern.match(s)
    if md
      configured_domain_name = md[1]
    else
      configured_domain_name = nil
    end

    config("#{@domain} abc.com")

    domain_name = node.domain_name
    assert_equal('abc.com', domain_name)

    if configured_domain_name
      config("#{@domain} #{configured_domain_name}")
    else
      config("no #{@domain} abc.com")
    end
  end

  def test_get_system_uptime
    node.cache_flush

    cmd = node.cmd_ref.lookup('show_system', 'uptime').get_command
    pattern = node.cmd_ref.lookup('show_system', 'uptime').get_value

    md = assert_show_match(command: cmd, pattern: pattern)
    node_uptime = node.system_uptime

    observed_system_uptime = (
      (md[1].to_i * 86_400) +
      (md[2].to_i * 3600) +
      (md[3].to_i * 60) +
      (md[4].to_i)
    )
    delta = node_uptime - observed_system_uptime
    assert(delta < 10,
           "Error, System uptime delta is (#{delta}), expected (delta < 10)")
  end

  def test_get_last_reset_time
    if validate_property_excluded?('show_version', 'last_reset_time')
      assert_nil(node.last_reset_time)
      return
    end
    assert_output_check(command: 'show version',
                        pattern: /.*\nLast reset at \d+ usecs after  (.*)\n/,
                        check:   node.last_reset_time,
                        msg:     'Error, Last reset time does not match')
  end

  def test_get_last_reset_reason
    if validate_property_excluded?('show_version', 'last_reset_reason')
      assert_nil(node.last_reset_reason)
      return
    end
    assert_output_check(command: 'show version',
                        pattern: /.*\nLast reset.*\n\n?  Reason: (.*)\n/,
                        check:   node.last_reset_reason,
                        msg:     'Error, Last reset reason does not match')
  end

  def test_get_system_cpu_utilization
    if validate_property_excluded?('system', 'resources')
      assert_nil(node.system_cpu_utilization)
      return
    end
    cpu_utilization = node.system_cpu_utilization
    md = assert_show_match(
      command: 'show system resources',
      pattern: /.*CPU states  :   (\d+\.\d+)% user,   (\d+\.\d+)% kernel/)
    observed_cpu_utilization = md[1].to_f + md[2].to_f
    delta = cpu_utilization - observed_cpu_utilization
    assert(delta > -15.0 && delta < 15.0,
           "Error: delta #{delta}, not +- 15.0")
  end

  def test_get_boot
    if validate_property_excluded?('show_version', 'boot_image')
      assert_nil(node.boot)
      return
    end

    # /N(5|6|7)/
    #   kickstart image file is: bootflash:///n7000-s2-kickstart.7.3.0.D1.1.bin
    # /N(3|8|9)/
    #   NXOS image file is: bootflash:///nxos.7.0.3.I3.1.bin

    pattern = /(?:kickstart|NXOS) image file is:\s+(.*)$/
    assert_output_check(command: 'show version',
                        pattern: pattern,
                        check:   node.boot,
                        msg:     'Error, Kickstart Image does not match')
  end

  def test_get_system
    if validate_property_excluded?('system', 'resources')
      assert_nil(node.system)
      return
    end

    # /N(5|6|7)/
    # system image file is: bootflash:///n7000-s2-kickstart.7.3.0.D1.1.bin
    # /N(3|8|9)/
    # NXOS image file is: bootflash:///nxos.7.0.3.I3.1.bin

    pattern = /(?:system|NXOS) image file is:\s+(.*)$/
    assert_output_check(command: 'show version',
                        pattern: pattern,
                        check:   node.system,
                        msg:     'Error, System Image does not match')
  end
end
