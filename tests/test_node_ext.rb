# Copyright (c) 2013-2015 Cisco and/or its affiliates.
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

# TestNodeExt - Minitest for abstracted Node APIs
class TestNodeExt < CiscoTestCase
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

  def test_node_find_subconfig
    result = find_subconfig(show_run_ospf, /router ospf bar/)
    assert_equal("\
log-adjacency-changes
vrf red
 log-adjacency-changes detail
vrf blue",
                 result)

    assert_nil(find_subconfig(result, /vrf blue/))

    assert_equal('log-adjacency-changes detail',
                 find_subconfig(result, /vrf red/))

    assert_nil(find_subconfig(result, /vrf green/))
  end

  def test_node_find_ascii
    # Find an entry in the parent submode, ignoring nested submodes
    assert_equal(['log-adjacency-changes'],
                 find_ascii(show_run_ospf, /^log-adjacency-changes.*$/,
                            /router ospf bar/))
    # Find an entry in a nested submode
    assert_equal(['log-adjacency-changes detail'],
                 find_ascii(show_run_ospf, /^log-adjacency-changes.*$/,
                            /router ospf bar/, /vrf red/))
    # Submode exists but does not have a match
    assert_nil(find_ascii(show_run_ospf, /^log-adjacency-changes.*$/,
                          /router ospf bar/, /vrf blue/))
    # Submode does not exist
    assert_nil(find_ascii(show_run_ospf, /^log-adjacency-changes.*$/,
                          /router ospf bar/, /vrf green/))

    # Entry exists in submode only
    assert_nil(find_ascii(show_run_ospf, /^log-adjacency-changes.*$/,
                          /router ospf foo/))
  end

  def test_node_config_get
    result = node.config_get('show_version', 'system_image')
    assert_equal(result, node.system)
  end

  def test_node_config_get_regexp_tokens
    node.client.config(['interface loopback0', 'shutdown'])
    node.client.config(['interface loopback1', 'no shutdown'])

    result = node.config_get('interface', 'shutdown', 'loopback1')
    assert_nil(result)
  end

  def test_node_token_str_to_regexp
    token = ['/%s/i', '/%s foo %s/', '/zzz/i']
    args = %w(LoopBack2 no bar)
    expected = [/LoopBack2/i, /no foo bar/, /zzz/i]

    result = node.token_str_to_regexp(token, args)
    # puts "intersection: #{result & expected}, diff: #{result - expected}"
    assert_equal(expected, result)
  end

  def test_node_config_get_invalid
    assert_raises IndexError do # no entry
      node.config_get('feature', 'name')
    end
    assert_raises IndexError do # entry but no config_get
      node.config_get('show_system', 'resources')
    end
  end

  def test_node_config_get_default
    result = node.config_get_default('snmp_server', 'aaa_user_cache_timeout')
    assert_equal(result, 3600)
  end

  def test_node_config_get_default_invalid
    assert_raises IndexError do # no name entry
      node.config_get_default('show_version', 'foobar')
    end
    assert_raises IndexError do # no feature entry
      node.config_get_default('feature', 'name')
    end
    assert_raises IndexError do # no default_value defined
      node.config_get_default('show_version', 'version')
    end
  end

  def test_node_config_set
    node.config_set('snmp_server', 'aaa_user_cache_timeout', '', 100)
    run = node.client.show('show run all | inc snmp')
    val = find_one_ascii(run, /snmp-server aaa-user cache-timeout (\d+)/)
    assert_equal('100', val)

    node.config_set('snmp_server', 'aaa_user_cache_timeout', 'no', 100)
    run = node.client.show('show run all | inc snmp')
    val = find_one_ascii(run, /snmp-server aaa-user cache-timeout (\d+)/)
    assert_equal('3600', val)
  end

  def test_node_config_set_invalid
    assert_raises IndexError do
      node.config_set('feature', 'name')
    end
    assert_raises IndexError do # feature exists but no config_set
      node.config_set('show_version', 'system_image')
    end
    assert_raises ArgumentError do # not enough args
      node.config_set('vtp', 'domain')
    end
    assert_raises ArgumentError do # too many args
      node.config_set('vtp', 'domain', 'example.com', 'baz')
    end
  end

  def test_node_cli_caching
    @device.cmd('conf t ; ip domain-name minitest ; end')
    dom1 = node.domain_name
    @device.cmd('conf t ; no ip domain-name minitest ; end')
    dom2 = node.domain_name
    assert_equal(dom1, dom2) # cached output was used for dom2

    node.cache_flush
    dom3 = node.domain_name
    assert_not_equal(dom1, dom3)
  end

  def test_node_get_product_description
    product_description = node.product_description
    ref = cmd_ref.lookup('show_version', 'description')
    assert(ref, 'Error, reference not found')

    s = @device.cmd("#{ref.test_config_get}")
    pattern = ref.test_config_get_regex
    md = pattern.match(s)
    assert(md, "Error, no match found for #{pattern}")
    assert_equal(md[1], product_description,
                 'Error, Product description does not match')
  end

  def test_node_get_product_id
    product_id = node.product_id
    s = @device.cmd('show inventory | no-more')
    pattern = /NAME: \"Chassis\".*\nPID: (\S+)/
    md = pattern.match(s)
    assert(md, "Error, no match found for #{pattern}")
    assert_equal(md[1], product_id,
                 'Error, Product id does not match')
  end

  def test_node_get_product_version_id
    version_id = node.product_version_id
    s = @device.cmd('show inventory | no-more')
    pattern = /NAME: \"Chassis\".*\n.*VID: (\w+)/
    md = pattern.match(s)
    assert(md, "Error, no match found for #{pattern}")
    assert_equal(md[1], version_id,
                 'Error, Version id does not match')
  end

  def test_node_get_product_serial_number
    serial_number = node.product_serial_number
    s = @device.cmd('show inventory | no-more')
    pattern = /NAME: \"Chassis\".*\n.*SN: (\w+)/
    md = pattern.match(s)
    assert(md, "Error, no match found for #{pattern}")
    assert_equal(md[1], serial_number,
                 'Error, Serial number does not match')
  end

  def test_node_get_os
    os = node.os
    s = @device.cmd('show version | no-more')
    pattern = /\n(Cisco.*)\n/
    md = pattern.match(s)
    assert(md, "Error, no match found for #{pattern}")
    assert_equal(md[1], os,
                 'Error, OS version does not match')
  end

  def test_node_get_os_version
    os_version = node.os_version
    ref = cmd_ref.lookup('show_version', 'version')
    assert(ref, 'Error, reference not found')
    s = @device.cmd("#{ref.test_config_get}")
    pattern = ref.test_config_get_regex[1]
    md = pattern.match(s)
    assert(md, "Error, no match found for #{pattern}")
    assert_equal(md[1], os_version,
                 'Error, OS version does not match')
  end

  def test_node_get_host_name_when_not_set
    s = @device.cmd('show running-config all | no-more')
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
    node.cache_flush

    @device.cmd('configure terminal')
    @device.cmd('no hostname') if (switchname == false)
    @device.cmd('no switchname') if (switchname == true)
    @device.cmd('end')
    node.cache_flush

    name = node.host_name
    assert_equal('switch', name)

    @device.cmd('configure terminal')
    if configured_name
      @device.cmd("hostname #{configured_name}") if (switchname == false)
      @device.cmd("switchname #{configured_name}") if (switchname == true)
    else
      @device.cmd('no hostname') if (switchname == false)
      @device.cmd('no switchname') if (switchname == true)
    end
    @device.cmd('end')
    node.cache_flush
  end

  def test_node_get_host_name_when_set
    s = @device.cmd('show running-config all | no-more')
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
    node.cache_flush

    @device.cmd('configure terminal')
    @device.cmd('hostname xyz') if (switchname == false)
    @device.cmd('switchname xyz') if (switchname == true)
    @device.cmd('end')
    node.cache_flush

    host_name = node.host_name
    assert_equal('xyz', host_name)

    @device.cmd('configure terminal')
    if configured_name
      @device.cmd("hostname #{configured_name}") if (switchname == false)
      @device.cmd("switchname #{configured_name}") if (switchname == true)
    else
      @device.cmd('no hostname') if (switchname == false)
      @device.cmd('no switchname') if (switchname == true)
    end
    @device.cmd('end')
    node.cache_flush
  end

  def test_node_get_domain_name_when_not_set
    # Test with default vrf only
    s = @device.cmd("show running-config | incl '^ip domain-name'")
    pattern = /^ip domain-name (\S+)/
    md = pattern.match(s)
    if md
      configured_domain_name = md[1]
    else
      configured_domain_name = nil
    end
    node.cache_flush

    @device.cmd('configure terminal')
    @device.cmd("no ip domain-name #{configured_domain_name}")
    @device.cmd('end')
    node.cache_flush

    domain_name = node.domain_name
    assert_equal('', domain_name)

    @device.cmd('configure terminal')
    if configured_domain_name
      @device.cmd("ip domain-name #{configured_domain_name}")
    else
      @device.cmd('no ip domain-name abc.com')
    end
    @device.cmd('end')
    node.cache_flush
  end

  def test_node_get_domain_name_when_set
    s = @device.cmd('show running-config | no-more')
    pattern = /.*\nip domain-name (\S+)/
    md = pattern.match(s)
    if md
      configured_domain_name = md[1]
    else
      configured_domain_name = nil
    end
    node.cache_flush

    @device.cmd('configure terminal')
    @device.cmd('ip domain-name abc.com')
    @device.cmd('end')
    node.cache_flush

    domain_name = node.domain_name
    assert_equal('abc.com', domain_name)

    @device.cmd('configure terminal')
    if configured_domain_name
      @device.cmd("ip domain-name #{configured_domain_name}")
    else
      @device.cmd('no ip domain-name abc.com')
    end
    @device.cmd('end')
    node.cache_flush
  end

  def test_node_get_system_uptime
    node.cache_flush
    pattern = /.*System uptime:\s+(\d+) days, (\d+) hours, (\d+) minutes, (\d+) seconds/

    s = @device.cmd('show system uptime | no-more')
    node_uptime = node.system_uptime

    md = pattern.match(s)
    assert(md, "Error, no match found for #{pattern}")

    observed_system_uptime =
      (md[1].to_i * 86_400) + (md[2].to_i * 3600) + (md[3].to_i * 60) + (md[4].to_i)
    delta = node_uptime - observed_system_uptime
    assert(delta < 10,
           "Error, System uptime delta is (#{delta}), expected (delta < 10)")
  end

  def test_node_get_last_reset_time
    last_reset_time = node.last_reset_time
    ref = cmd_ref.lookup('show_version', 'last_reset_time')
    assert(ref, 'Error, reference not found')
    s = @device.cmd("#{ref.test_config_get}")
    pattern = ref.test_config_get_regex
    md = pattern.match(s)
    # N9k doesn't provide this info at present.
    if !last_reset_time.empty?
      assert(md, "Error, no match found for #{pattern}")
      assert_equal(md[1], last_reset_time,
                   'Error, Last reset time does not match')
    else
      assert(!md, "Error, output found in ASCII '#{md}' but not in node")
    end
  end

  def test_node_get_last_reset_reason
    last_reset_reason = node.last_reset_reason
    ref = cmd_ref.lookup('show_version', 'last_reset_reason')
    assert(ref, 'Error, reference not found')
    s = @device.cmd("#{ref.test_config_get}")
    pattern = ref.test_config_get_regex
    md = pattern.match(s)
    refute_nil(md, 'ERROR: last reset reason not shown')
    assert(md, "Error, no match found for #{pattern}")
    assert_equal(md[1], last_reset_reason,
                 'Error, Last reset reason does not match')
  end

  def test_node_get_system_cpu_utilization
    cpu_utilization = node.system_cpu_utilization
    ref = cmd_ref.lookup('system', 'resources')
    assert(ref, 'Error, reference not found')
    s = @device.cmd("#{ref.test_config_get}")
    pattern = ref.test_config_get_regex
    md = pattern.match(s)
    assert(md, "Error, md not populated, #{s}")
    observed_cpu_utilization = md[1].to_f + md[2].to_f
    delta = cpu_utilization - observed_cpu_utilization
    assert(delta > -15.0 && delta < 15.0,
           "Error: delta #{delta}, not +- 15.0")
  end

  def test_node_get_boot
    boot = node.boot
    ref = cmd_ref.lookup('show_version', 'boot_image')
    assert(ref, 'Error, reference not found')
    s = @device.cmd("#{ref.test_config_get}")
    s =~ ref.test_config_get_regex
    assert_equal(Regexp.last_match(1), boot,
                 'Error, Kickstart Image does not match')
  end

  def test_node_get_system
    system = node.system
    ref = cmd_ref.lookup('show_version', 'system_image')
    assert(ref, 'Error, reference not found')
    s = @device.cmd("#{ref.test_config_get}")
    s =~ ref.test_config_get_regex
    assert_equal(Regexp.last_match(1), system,
                 'Error, System Image does not match')
  end
end
