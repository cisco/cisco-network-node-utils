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
require File.expand_path('../../lib/cisco_node_utils/snmpserver', __FILE__)

# TestSnmpServer - Minitest for SnmpServer node utility
class TestSnmpServer < CiscoTestCase
  DEFAULT_SNMP_SERVER_AAA_USER_CACHE_TIMEOUT = 3600
  DEFAULT_SNMP_SERVER_LOCATION = ''
  DEFAULT_SNMP_SERVER_CONTACT = ''
  DEFAULT_SNMP_SERVER_PACKET_SIZE = 1500
  DEFAULT_SNMP_SERVER_GLOBAL_ENFORCE_PRIVACY = false
  DEFAULT_SNMP_SERVER_PROTOCOL_ENABLE = true
  DEFAULT_SNMP_SERVER_TCP_SESSION_AUTH = true

  def test_snmpserver_aaa_user_cache_timeout_set_invalid_upper_range
    snmpserver = SnmpServer.new
    assert_raises(Cisco::CliError) do
      snmpserver.aaa_user_cache_timeout = 86_401
    end
  end

  def test_snmpserver_aaa_user_cache_timeout_set_invalid_lower_range
    snmpserver = SnmpServer.new
    assert_raises(Cisco::CliError) do
      snmpserver.aaa_user_cache_timeout = 0
    end
  end

  def test_snmpserver_aaa_user_cache_timeout_set_valid
    snmpserver = SnmpServer.new
    newtimeout = 1400
    snmpserver.aaa_user_cache_timeout = newtimeout
    s = @device.cmd('show run snmp all | no-more')
    cmd = 'snmp-server aaa-user cache-timeout'
    line = /#{cmd} (\d+)/.match(s)
    timeout = line.to_s.split(' ').last.to_i
    assert_equal(timeout, newtimeout)
    # set to default
    snmpserver.aaa_user_cache_timeout = snmpserver.default_aaa_user_cache_timeout
  end

  def test_snmpserver_aaa_user_cache_timeout_set_default_valid
    snmpserver = SnmpServer.new
    snmpserver.aaa_user_cache_timeout =
      snmpserver.default_aaa_user_cache_timeout
    s = @device.cmd('show run snmp all | no-more')
    cmd = 'snmp-server aaa-user cache-timeout'
    line = /#{cmd} (\d+)/.match(s)
    timeout = line.to_s.split(' ').last.to_i
    assert_equal(timeout, snmpserver.aaa_user_cache_timeout)
  end

  def test_snmpserver_aaa_user_cache_timeout_get
    snmpserver = SnmpServer.new
    s = @device.cmd('show run snmp all | no-more')
    cmd = 'snmp-server aaa-user cache-timeout'
    line = /#{cmd} (\d+)/.match(s)
    timeout = line.to_s.split(' ').last.to_i
    assert_equal(timeout, snmpserver.aaa_user_cache_timeout)
  end

  def test_snmpserver_sys_contact_get
    snmpserver = SnmpServer.new
    snmpserver.contact = 'test-contact'
    s = @device.cmd('show snmp | no-more')
    line = /sys contact: [^\n\r]+/.match(s)
    contact = ''
    contact = line.to_s.gsub('sys contact:', '').strip unless line.nil?
    # puts "contact : #{line}, #{snmpserver.contact}"
    assert_equal(contact, snmpserver.contact)
    # set to default
    snmpserver.contact = snmpserver.default_contact
  end

  def test_snmpserver_sys_contact_set_invalid
    snmpserver = SnmpServer.new
    assert_raises(TypeError) do
      snmpserver.contact = 123
    end
  end

  def test_snmpserver_sys_contact_set_zero_length
    snmpserver = SnmpServer.new
    newcontact = ''
    snmpserver.contact = newcontact
    assert_equal(newcontact, snmpserver.contact)
    # set to default
    snmpserver.contact = snmpserver.default_contact
  end

  def test_snmpserver_sys_contact_set_valid
    snmpserver = SnmpServer.new
    newcontact = 'mvenkata_test# contact'
    snmpserver.contact = newcontact
    s = @device.cmd('show snmp | no-more')
    line = /sys contact: [^\n\r]+/.match(s)
    # puts "line: #{line}"
    contact = line.to_s.gsub('sys contact:', '').strip
    assert_equal(contact, newcontact)
    # set to default
    snmpserver.contact = snmpserver.default_contact
  end

  def test_snmpserver_sys_contact_set_special_chars
    snmpserver = SnmpServer.new
    # newcontact = "Test{}(%tuvy@_cisco contact$#!@1234^&*()_+"
    newcontact = 'user@example.com @$%&}test ]|[#_@test contact'
    snmpserver.contact = newcontact
    s = @device.cmd('show snmp | no-more')
    line = /sys contact: [^\n\r]+/.match(s)
    # puts "line: #{line}"
    contact = line.to_s.gsub('sys contact:', '').strip
    assert_equal(contact, newcontact)
    # set to default
    snmpserver.contact = snmpserver.default_contact
  end

  def test_snmpserver_sys_contact_set_default
    snmpserver = SnmpServer.new
    snmpserver.contact = snmpserver.default_contact
    s = @device.cmd('show snmp | no-more')
    line = /sys contact: [^\n\r]+/.match(s)
    contact = ''
    contact = line.to_s.gsub('sys contact:', '').strip unless line.nil?
    assert_equal(contact, snmpserver.default_contact)
  end

  def test_snmpserver_sys_location_get
    snmpserver = SnmpServer.new
    # set location
    snmpserver.location = 'test-location'
    s = @device.cmd('show snmp | no-more')
    line = /sys location: [^\n\r]+/.match(s)
    location = ''
    location = line.to_s.gsub('sys location:', '').strip unless line.nil?
    # puts "location : #{location}, #{snmpserver.location}"
    assert_equal(location, snmpserver.location)
    # set to default
    snmpserver.location = snmpserver.default_location
  end

  def test_snmpserver_sys_location_set_invalid
    snmpserver = SnmpServer.new
    assert_raises(TypeError) do
      snmpserver.location = 123
    end
  end

  def test_snmpserver_sys_location_set_zero_length
    snmpserver = SnmpServer.new
    newlocation = ''
    snmpserver.location = newlocation
    assert_equal(newlocation, snmpserver.location)
  end

  def test_snmpserver_sys_location_set_valid
    snmpserver = SnmpServer.new
    newlocation = 'bxb-300-2-1 test location'
    snmpserver.location = newlocation
    s = @device.cmd('show snmp | no-more')
    line = /sys location: [^\n\r]+/.match(s)
    location = line.to_s.gsub('sys location:', '').strip
    assert_equal(location, newlocation)
    # set to default
    snmpserver.location = snmpserver.default_location
  end

  def test_snmpserver_sys_location_set_special_chars
    snmpserver = SnmpServer.new
    newlocation = 'bxb-300 2nd floor test !$%^33&&*) location'
    snmpserver.location = newlocation
    s = @device.cmd('show snmp | no-more')
    line = /sys location: [^\n\r]+/.match(s)
    location = line.to_s.gsub('sys location:', '').strip
    assert_equal(location, newlocation)
    # set to default
    snmpserver.location = snmpserver.default_location
  end

  def test_snmpserver_sys_location_set_default
    snmpserver = SnmpServer.new
    #    snmpserver.location = snmpserver.default_location
    snmpserver.location = 'FOO'
    s = @device.cmd('show snmp | no-more')
    line = /sys location: [^\n\r]+/.match(s)
    location = ''
    location = line.to_s.gsub('sys location:', '').strip unless line.nil?
    assert_equal(location, snmpserver.location)
    # set to default
    snmpserver.location = snmpserver.default_location
  end

  def test_snmpserver_packetsize_get
    snmpserver = SnmpServer.new
    snmpserver.packet_size = 2000
    s = @device.cmd('show run snmp all | no-more')
    cmd = 'snmp-server packetsize'
    line = /#{cmd} (\d+)/.match(s)
    packetsize = 0
    packetsize = line.to_s.split(' ').last.to_i unless line.nil?
    assert_equal(packetsize, snmpserver.packet_size)
    # unset to default
    snmpserver.packet_size = 0
  end

  def test_snmpserver_packetsize_set_invalid_upper_range
    snmpserver = SnmpServer.new
    newpacketsize = 17_383
    assert_raises(Cisco::CliError) do
      snmpserver.packet_size = newpacketsize
    end
  end

  def test_snmpserver_packetsize_set_invalid_lower_range
    snmpserver = SnmpServer.new
    newpacketsize = 480
    assert_raises(Cisco::CliError) do
      snmpserver.packet_size = newpacketsize
    end
  end

  def test_snmpserver_packetsize_set_valid
    snmpserver = SnmpServer.new
    newpacketsize = 1600
    snmpserver.packet_size = newpacketsize
    s = @device.cmd('show run snmp all | no-more')
    cmd = 'snmp-server packetsize'
    line = /#{cmd} (\d+)/.match(s)
    packetsize = line.to_s.split(' ').last.to_i
    assert_equal(packetsize, newpacketsize)
    # unset to default
    snmpserver.packet_size = 0
  end

  def test_snmpserver_packetsize_set_default
    snmpserver = SnmpServer.new

    s = @device.cmd('show run snmp all | no-more')
    cmd = 'snmp-server packetsize'
    line = /#{cmd} (\d+)/.match(s)
    packetsize = line.to_s.split(' ').last.to_i
    assert_equal(packetsize, snmpserver.packet_size,
                 'Error: Snmp Server, packet size not default')

    snmpserver.packet_size = 850
    s = @device.cmd('show run snmp all | no-more')
    cmd = 'snmp-server packetsize'
    line = /#{cmd} (\d+)/.match(s)
    packetsize = line.to_s.split(' ').last.to_i
    assert_equal(packetsize, snmpserver.packet_size,
                 'Error: Snmp Server, packet size not default')

    snmpserver.packet_size = snmpserver.default_packet_size
    s = @device.cmd('show run snmp all | no-more')
    cmd = 'snmp-server packetsize'
    line = /#{cmd} (\d+)/.match(s)
    packetsize = line.to_s.split(' ').last.to_i
    assert_equal(packetsize, snmpserver.packet_size,
                 'Error: Snmp Server, packet size not default')
    # set to default
    snmpserver.packet_size = 0
  end

  def test_snmpserver_packetsize_unset
    snmpserver = SnmpServer.new

    # Get orginal packet size
    org_packet_size = snmpserver.packet_size
    snmpserver.packet_size = 0
    s = @device.cmd('show run snmp all | no-more')
    cmd = 'snmp-server packetsize'
    line = /#{cmd} (\d+)/.match(s)
    packetsize = line.to_s.split(' ').last.to_i
    assert_equal(packetsize, snmpserver.packet_size,
                 'Error: Snmp Server, packet size not unset')

    # Restore packet size
    snmpserver.packet_size = org_packet_size
    assert_equal(org_packet_size, snmpserver.packet_size,
                 'Error: Snmp Server, packet size not restored')
    # set to default
    snmpserver.packet_size = 0
  end

  def test_snmpserver_global_enforce_priv_get_default
    snmpserver = SnmpServer.new
    # default is false
    snmpserver.global_enforce_priv = false
    device_enabled = snmpserver.global_enforce_priv?
    s = @device.cmd('show run snmp all | no-more')
    cmd = 'no snmp-server globalEnforcePriv'
    line = /#{cmd}/.match(s)
    assert_equal(line.nil?, device_enabled)
    # set to default
    snmpserver.global_enforce_priv = snmpserver.default_global_enforce_priv
  end

  def test_snmpserver_global_enforce_priv_get_enabled
    snmpserver = SnmpServer.new
    snmpserver.global_enforce_priv = true
    device_enabled = snmpserver.global_enforce_priv?
    s = @device.cmd('show run snmp all | no-more')
    cmd = 'snmp-server globalEnforcePriv'
    line = /#{cmd}/.match(s)
    assert_equal(!line.nil?, device_enabled)
    # set to default
    snmpserver.global_enforce_priv = snmpserver.default_global_enforce_priv
  end

  def test_snmpserver_global_enforce_priv_set_enabled
    snmpserver = SnmpServer.new
    snmpserver.global_enforce_priv = true
    s = @device.cmd('show run snmp all | no-more')
    cmd = 'snmp-server globalEnforcePriv'
    line = /#{cmd}/.match(s)
    # puts "line : #{line}"
    assert_equal(!line.nil?, true)
    # set to default
    snmpserver.global_enforce_priv = snmpserver.default_global_enforce_priv
  end

  def test_snmpserver_global_enforce_priv_set_disabled
    snmpserver = SnmpServer.new
    snmpserver.global_enforce_priv = false
    s = @device.cmd('show run snmp all | no-more')
    cmd = 'no snmp-server globalEnforcePriv'
    line = /#{cmd}/.match(s)
    assert_equal(line.nil?, false)
    # set to default
    snmpserver.global_enforce_priv = snmpserver.default_global_enforce_priv
  end

  def test_snmpserver_protocol_get_default
    snmpserver = SnmpServer.new
    # set default
    snmpserver.protocol = true
    cmd = '^snmp-server protocol enable'
    s = @device.cmd("show run snmp all | i '#{cmd}'")
    assert_match(/#{cmd}/, s)
    # set to default
    snmpserver.protocol = snmpserver.default_protocol
  end

  def test_snmpserver_protocol_get_disabled
    snmpserver = SnmpServer.new
    snmpserver.protocol = false
    device_enabled = snmpserver.protocol?
    s = @device.cmd('show run snmp all | no-more')
    cmd = 'no snmp-server protocol enable'
    line = /#{cmd}/.match(s)
    # puts "line #{line}"
    assert_equal(line.nil?, device_enabled)
    # set to default
    snmpserver.protocol = snmpserver.default_protocol
  end

  def test_snmpserver_protocol_set_enabled
    snmpserver = SnmpServer.new
    snmpserver.protocol = true
    s = @device.cmd('show run snmp all | no-more')
    cmd = 'snmp-server protocol enable'
    line = /#{cmd}/.match(s)
    # puts "line : #{line}"
    assert_equal(!line.nil?, true)
    # set to default
    snmpserver.protocol = snmpserver.default_protocol
  end

  def test_snmpserver_protocol_set_disabled
    snmpserver = SnmpServer.new
    snmpserver.protocol = false
    s = @device.cmd('show run snmp all | no-more')
    cmd = 'no snmp-server protocol enable'
    line = /#{cmd}/.match(s)
    # puts "line : #{line}"
    assert_equal(line.nil?, false)
    # set to default
    snmpserver.protocol = snmpserver.default_protocol
  end

  def test_snmpserver_tcp_session_auth_get_default
    snmpserver = SnmpServer.new
    # default value is false
    snmpserver.tcp_session_auth = false
    device_enabled = snmpserver.tcp_session_auth?
    s = @device.cmd('show run snmp all | no-more')
    cmd = 'no snmp-server tcp-session auth'
    line = /#{cmd}/.match(s)
    assert_equal(line.nil?, device_enabled)
    # set to default
    snmpserver.tcp_session_auth = snmpserver.default_tcp_session_auth
  end

  def test_snmpserver_tcp_session_auth_get_enabled
    snmpserver = SnmpServer.new
    snmpserver.tcp_session_auth = true
    cmd = '^snmp-server tcp-session auth'
    s = @device.cmd("show run snmp all | i '#{cmd}'")
    assert_match(/#{cmd}/, s)
    # set to default
    snmpserver.tcp_session_auth = snmpserver.default_tcp_session_auth
  end

  def test_snmpserver_tcp_session_auth_set_enabled
    snmpserver = SnmpServer.new
    snmpserver.tcp_session_auth = true
    s = @device.cmd('show run snmp all | no-more')
    cmd = 'snmp-server tcp-session auth'
    line = /#{cmd}/.match(s)
    # puts "line : #{line}"
    assert_equal(!line.nil?, true)
    # set to default
    snmpserver.tcp_session_auth = snmpserver.default_tcp_session_auth
  end

  def test_snmpserver_tcp_session_auth_set_default
    snmpserver = SnmpServer.new
    snmpserver.tcp_session_auth = false
    s = @device.cmd('show run snmp all | no-more')
    cmd = 'no snmp-server tcp-session auth'
    line = /#{cmd}/.match(s)
    # puts "line : #{line}"
    assert_equal(line.nil?, false)
    # set to default
    snmpserver.tcp_session_auth = snmpserver.default_tcp_session_auth
  end
end
