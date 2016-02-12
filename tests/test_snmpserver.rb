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
require_relative '../lib/cisco_node_utils/snmpserver'

# TestSnmpServer - Minitest for SnmpServer node utility
class TestSnmpServer < CiscoTestCase
  DEFAULT_SNMP_SERVER_AAA_USER_CACHE_TIMEOUT = 3600
  DEFAULT_SNMP_SERVER_LOCATION = ''
  DEFAULT_SNMP_SERVER_CONTACT = ''
  DEFAULT_SNMP_SERVER_PACKET_SIZE = 1500
  DEFAULT_SNMP_SERVER_GLOBAL_ENFORCE_PRIVACY = false
  DEFAULT_SNMP_SERVER_PROTOCOL_ENABLE = true
  DEFAULT_SNMP_SERVER_TCP_SESSION_AUTH = true

  def setup
    super
    @default_show_command = 'show run snmp all | no-more'
    # set all commands to defaults
    s = SnmpServer.new
    s.aaa_user_cache_timeout = s.default_aaa_user_cache_timeout
    s.contact = s.default_contact
    s.global_enforce_priv = s.default_global_enforce_priv
    s.location = s.default_location
    s.packet_size = 0
    s.protocol = s.default_protocol
    s.tcp_session_auth = s.default_tcp_session_auth
  end

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
    line = assert_show_match(
      pattern: /snmp-server aaa-user cache-timeout (\d+)/)
    timeout = line.to_s.split(' ').last.to_i
    assert_equal(timeout, newtimeout)
    # set to default
    snmpserver.aaa_user_cache_timeout =
      snmpserver.default_aaa_user_cache_timeout
  end

  def test_snmpserver_aaa_user_cache_timeout_set_default_valid
    snmpserver = SnmpServer.new
    snmpserver.aaa_user_cache_timeout =
      snmpserver.default_aaa_user_cache_timeout
    line = assert_show_match(
      pattern: /snmp-server aaa-user cache-timeout (\d+)/)
    timeout = line.to_s.split(' ').last.to_i
    assert_equal(timeout, snmpserver.aaa_user_cache_timeout)
  end

  def test_snmpserver_aaa_user_cache_timeout_get
    snmpserver = SnmpServer.new
    line = assert_show_match(
      pattern: /snmp-server aaa-user cache-timeout (\d+)/)
    timeout = line.to_s.split(' ').last.to_i
    assert_equal(timeout, snmpserver.aaa_user_cache_timeout)
  end

  def test_snmpserver_sys_contact_get
    snmpserver = SnmpServer.new
    snmpserver.contact = 'test-contact'
    line = assert_show_match(command: 'show snmp | no-more',
                             pattern: /sys contact: [^\n\r]+/)
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
    line = assert_show_match(command: 'show snmp | no-more',
                             pattern: /sys contact: [^\n\r]+/)
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
    line = assert_show_match(command: 'show snmp | no-more',
                             pattern: /sys contact: [^\n\r]+/)
    # puts "line: #{line}"
    contact = line.to_s.gsub('sys contact:', '').strip
    assert_equal(contact, newcontact)
    # set to default
    snmpserver.contact = snmpserver.default_contact
  end

  def test_snmpserver_sys_contact_set_default
    snmpserver = SnmpServer.new
    snmpserver.contact = snmpserver.default_contact
    line = assert_show_match(command: 'show snmp | no-more',
                             pattern: /sys contact: [^\n\r]*/)
    contact = ''
    contact = line.to_s.gsub('sys contact:', '').strip unless line.nil?
    assert_equal(contact, snmpserver.default_contact)
  end

  def test_snmpserver_sys_location_get
    snmpserver = SnmpServer.new
    # set location
    snmpserver.location = 'test-location'
    line = assert_show_match(command: 'show snmp | no-more',
                             pattern: /sys location: [^\n\r]+/)
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
    line = assert_show_match(command: 'show snmp | no-more',
                             pattern: /sys location: [^\n\r]+/)
    location = line.to_s.gsub('sys location:', '').strip
    assert_equal(location, newlocation)
    # set to default
    snmpserver.location = snmpserver.default_location
  end

  def test_snmpserver_sys_location_set_special_chars
    snmpserver = SnmpServer.new
    newlocation = 'bxb-300 2nd floor test !$%^33&&*) location'
    snmpserver.location = newlocation
    line = assert_show_match(command: 'show snmp | no-more',
                             pattern: /sys location: [^\n\r]+/)
    location = line.to_s.gsub('sys location:', '').strip
    assert_equal(location, newlocation)
    # set to default
    snmpserver.location = snmpserver.default_location
  end

  def test_snmpserver_sys_location_set_default
    snmpserver = SnmpServer.new
    #    snmpserver.location = snmpserver.default_location
    snmpserver.location = 'FOO'
    line = assert_show_match(command: 'show snmp | no-more',
                             pattern: /sys location: [^\n\r]+/)
    location = ''
    location = line.to_s.gsub('sys location:', '').strip unless line.nil?
    assert_equal(location, snmpserver.location)
    # set to default
    snmpserver.location = snmpserver.default_location
  end

  def test_snmpserver_packetsize_get
    snmpserver = SnmpServer.new
    snmpserver.packet_size = 2000
    line = assert_show_match(pattern: /snmp-server packetsize (\d+)/)
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
    line = assert_show_match(pattern: /snmp-server packetsize (\d+)/)
    packetsize = line.to_s.split(' ').last.to_i
    assert_equal(packetsize, newpacketsize)
    # unset to default
    snmpserver.packet_size = 0
  end

  def test_snmpserver_packetsize_set_default
    snmpserver = SnmpServer.new
    refute_show_match(pattern: /snmp-server packetsize (\d+)/)
    assert_equal(0, snmpserver.packet_size,
                 'Error: Snmp Server, packet size not default')

    snmpserver.packet_size = 850
    line = assert_show_match(pattern: /snmp-server packetsize (\d+)/)
    packetsize = line.to_s.split(' ').last.to_i
    assert_equal(packetsize, snmpserver.packet_size,
                 'Error: Snmp Server, packet size not default')

    snmpserver.packet_size = snmpserver.default_packet_size
    # TODO: this seems weird, why is default_packet_size not 0 as above?
    line = assert_show_match(pattern: /snmp-server packetsize (\d+)/)
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
    refute_show_match(pattern: /snmp-server packetsize (\d+)/)
    assert_equal(0, snmpserver.packet_size,
                 'Error: Snmp Server, packet size not unset')

    # Restore packet size
    snmpserver.packet_size = org_packet_size
    assert_equal(org_packet_size, snmpserver.packet_size,
                 'Error: Snmp Server, packet size not restored')
    # set to default
    snmpserver.packet_size = 0
  end

  def test_snmpserver_global_enforce_priv
    snmpserver = SnmpServer.new
    default = snmpserver.default_global_enforce_priv
    snmpserver.global_enforce_priv = default
    if default == true
      assert_show_match(pattern: /^snmp-server globalEnforcePriv/)
      assert(snmpserver.global_enforce_priv?)

      snmpserver.global_enforce_priv = false
      assert_show_match(pattern: /^no snmp-server globalEnforcePriv/)
      refute(snmpserver.global_enforce_priv?)
    else
      assert_show_match(pattern: /^no snmp-server globalEnforcePriv/)
      refute(snmpserver.global_enforce_priv?)

      snmpserver.global_enforce_priv = true
      assert_show_match(pattern: /^snmp-server globalEnforcePriv/)
      assert(snmpserver.global_enforce_priv?)
    end
    # Cleanup
    snmpserver.global_enforce_priv = snmpserver.default_global_enforce_priv
  end

  def test_snmpserver_protocol_get_set
    snmpserver = SnmpServer.new
    snmpserver.protocol = false
    assert_equal(false, snmpserver.protocol?)
    snmpserver.protocol =
      snmpserver.default_protocol
    assert_equal(snmpserver.default_protocol,
                 snmpserver.protocol?)
  end

  def test_snmpserver_tcp_session_auth_get_set
    snmpserver = SnmpServer.new
    snmpserver.tcp_session_auth = false
    assert_equal(false, snmpserver.tcp_session_auth?)
    snmpserver.tcp_session_auth =
      snmpserver.default_tcp_session_auth
    assert_equal(snmpserver.default_tcp_session_auth,
                 snmpserver.tcp_session_auth?)
  end
end
