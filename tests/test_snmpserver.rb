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
  @skip_unless_supported = 'snmp_server'

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
    if platform == :nexus
      s.aaa_user_cache_timeout = s.default_aaa_user_cache_timeout
      s.contact = s.default_contact
      s.global_enforce_priv = s.default_global_enforce_priv
      s.location = s.default_location
      s.packet_size = 0
      s.protocol = s.default_protocol
      s.tcp_session_auth = s.default_tcp_session_auth
    else
      s.contact = s.default_contact
      s.location = s.default_location
    end
  end

  def test_aaa_user_cache_timeout
    if validate_property_excluded?('snmp_server', 'aaa_user_cache_timeout')
      assert_raises(Cisco::UnsupportedError) do
        SnmpServer.new.aaa_user_cache_timeout = 1400
      end
      return
    end

    s = SnmpServer.new
    # initial
    default = s.default_aaa_user_cache_timeout
    assert_equal(default, s.aaa_user_cache_timeout)

    # non-default
    s.aaa_user_cache_timeout = 1400
    assert_equal(1400, s.aaa_user_cache_timeout)

    # default
    s.aaa_user_cache_timeout = default
    assert_equal(default, s.aaa_user_cache_timeout)

    # negative tests
    assert_raises(Cisco::CliError) { s.aaa_user_cache_timeout = 86_401 }
    assert_raises(Cisco::CliError) { s.aaa_user_cache_timeout = 0 }
  end

  def test_contact
    s = SnmpServer.new
    # initial
    default = s.default_contact
    assert_equal(default, s.contact)

    # non-default
    s.contact = 'minitest'
    assert_equal('minitest', s.contact)

    # default
    s.contact = default
    assert_equal(default, s.contact)

    # empty
    s.contact = ''
    assert_equal('', s.contact)

    # negative test
    assert_raises(TypeError) { s.contact = 123 }
  end

  def test_contact_special_chars
    snmpserver = SnmpServer.new
    newcontact = 'user@example.com @$%&}test ]|[#_@test contact'
    snmpserver.contact = newcontact
    if platform == :nexus
      line = assert_show_match(command: 'show snmp | no-more',
                               pattern: /sys contact: [^\n\r]+/)
      # puts "line: #{line}"
      contact = line.to_s.gsub('sys contact:', '').strip
    else
      line = assert_show_match(command: 'show running-config snmp-server',
                               pattern: /snmp-server contact [^\n\r]+/)
      contact = ''
      contact = line.to_s.gsub('snmp-server contact', '').strip unless line.nil?
    end
    assert_equal(contact, newcontact)
    # set to default
    snmpserver.contact = snmpserver.default_contact
  end

  def test_location
    s = SnmpServer.new
    # initial
    default = s.default_location
    assert_equal(default, s.location)

    # non-default
    s.location = 'minitest'
    assert_equal('minitest', s.location)

    # default
    s.location = default
    assert_equal(default, s.location)

    # empty
    s.location = ''
    assert_equal('', s.location)

    # negative test
    assert_raises(TypeError) { s.location = 123 }
  end

  def test_location_special_chars
    snmpserver = SnmpServer.new
    newlocation = 'bxb-300 2nd floor test !$%^33&&*) location'
    snmpserver.location = newlocation
    if platform == :nexus
      line = assert_show_match(command: 'show snmp | no-more',
                               pattern: /sys location: [^\n\r]+/)
      location = line.to_s.gsub('sys location:', '').strip
    else
      line = assert_show_match(command: 'show running-config snmp-server',
                               pattern: /snmp-server location [^\n\r]+/)
      location = line.to_s.gsub('snmp-server location', '').strip
    end
    assert_equal(location, newlocation)
    # set to default
    snmpserver.location = snmpserver.default_location
  end

  def test_packet_size
    skip_legacy_defect?('7.0.3.I2.2e|7.0.3.I2.5|7.0.3.I3.1|7.3.2.D',
                        'CSCuz14217: CLI shows default snmp packet-size incorrectly as 0')

    if validate_property_excluded?('snmp_server', 'packet_size')
      assert_raises(Cisco::UnsupportedError) do
        SnmpServer.new.packet_size = 2000
      end
      return
    end

    s = SnmpServer.new
    # initial
    default = s.default_packet_size
    assert_equal(default, s.packet_size)

    # non-default
    s.packet_size = 1400
    assert_equal(1400, s.packet_size)

    # default
    s.packet_size = default
    assert_equal(default, s.packet_size)

    # negative tests
    assert_raises(Cisco::CliError) { s.packet_size = 17_383 } # upper bound
    assert_raises(Cisco::CliError) { s.packet_size = 480 }    # lower bound
  end

  def test_global_enforce_priv
    if validate_property_excluded?('snmp_server', 'global_enforce_priv')
      assert_raises(Cisco::UnsupportedError) do
        SnmpServer.new.global_enforce_priv = true
      end
      return
    end

    s = SnmpServer.new
    # initial
    default = s.default_global_enforce_priv
    assert_equal(default, s.global_enforce_priv?)

    # non-default
    s.global_enforce_priv = !default
    assert_equal(!default, s.global_enforce_priv?)

    # default
    s.global_enforce_priv = default
    assert_equal(default, s.global_enforce_priv?)
  end

  def test_protocol
    if validate_property_excluded?('snmp_server', 'protocol')
      assert_raises(Cisco::UnsupportedError) do
        SnmpServer.new.protocol = true
      end
      return
    end

    s = SnmpServer.new
    # initial
    default = s.default_protocol
    assert_equal(default, s.protocol?)

    # non-default
    s.protocol = !default
    assert_equal(!default, s.protocol?)

    # default
    s.protocol = default
    assert_equal(default, s.protocol?)
  end

  def test_tcp_session_auth
    if validate_property_excluded?('snmp_server', 'tcp_session_auth')
      assert_raises(Cisco::UnsupportedError) do
        SnmpServer.new.tcp_session_auth = true
      end
      return
    end

    s = SnmpServer.new
    # initial
    default = s.default_tcp_session_auth
    assert_equal(default, s.tcp_session_auth?)

    # non-default
    s.tcp_session_auth = !default
    assert_equal(!default, s.tcp_session_auth?)

    # default
    s.tcp_session_auth = default
    assert_equal(default, s.tcp_session_auth?)
  end
end
