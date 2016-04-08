# Copyright (c) 2015-2016 Cisco and/or its affiliates.
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
require_relative '../lib/cisco_node_utils/acl'
require_relative '../lib/cisco_node_utils/ace'

# TestAce - Minitest for Ace node utility class
class TestAce < CiscoTestCase
  @skip_unless_supported = 'acl'
  @@pre_clean_needed = true # rubocop:disable Style/ClassVars

  def setup
    super
    remove_all_acls if @@pre_clean_needed
    @@pre_clean_needed = false # rubocop:disable Style/ClassVars
  end

  def teardown
    super
    remove_all_acls
  end

  def remove_all_acls
    Acl.acls.each do |_afis, acls|
      acls.values.each(&:destroy)
    end
  end

  # Helper to create an ACE and return the obj. The test_hash contains
  # only the minimum properties which can be added to or overwritten as
  # required for each test.
  def ace_helper(afi, props=nil)
    test_hash = {
      action:   'permit',
      proto:    'tcp',
      src_addr: 'any',
      dst_addr: 'any',
    }
    test_hash.merge!(props) unless props.nil?

    a = Ace.new(afi, afi, 10)
    begin
      a.ace_set(test_hash)
      a
    end
  rescue CliError => e
    skip('This property is not supported on this platform') if
      e.message[/(Invalid parameter detected|Invalid command)/]
    flunk(e.message)
  end

  # TESTS
  def test_remark
    %w(ipv4 ipv6).each do |afi|
      a = ace_helper(afi, remark: afi)
      assert_equal(afi, a.remark)
    end
  end

  def test_action
    %w(ipv4 ipv6).each do |afi|
      %w(permit deny).each do |val|
        a = ace_helper(afi, action: val)
        assert_equal(val, a.action)
      end
    end
  end

  def test_proto
    %w(ipv4 ipv6).each do |afi|
      # Sampling of proto's
      %w(ip tcp udp).each do |val|
        val = 'ipv6' if val[/ip/] && afi[/ipv6/]
        a = ace_helper(afi, proto: val)
        assert_equal(val, a.proto)
      end
    end
  end

  def test_addrs
    val = '10.1.1.1/32'
    a = ace_helper('ipv4', src_addr: val, dst_addr: val)
    assert_equal(val, a.src_addr)
    assert_equal(val, a.dst_addr)

    val = '10.1.1.1 0.0.0.0'
    exp = '10.1.1.1/32'
    # This syntax will transform to 10.1.1.1/32
    a = ace_helper('ipv4', src_addr: val, dst_addr: val)
    assert_equal(exp, a.src_addr)
    assert_equal(exp, a.dst_addr)

    val = '10.1.1.1 2.3.4.5'
    a = ace_helper('ipv4', src_addr: val, dst_addr: val)
    assert_equal(val, a.src_addr)
    assert_equal(val, a.dst_addr)

    val = '10:1:1::1/128'
    a = ace_helper('ipv6', src_addr: val, dst_addr: val)
    assert_equal(val, a.src_addr)
    assert_equal(val, a.dst_addr)

    %w(ipv4 ipv6).each do |afi|
      val = "addrgroup my_addrgroup_#{afi}"
      a = ace_helper(afi, src_addr: val, dst_addr: val)
      assert_equal(val, a.src_addr)
      assert_equal(val, a.dst_addr)
    end
  end

  def test_ports
    %w(ipv4 ipv6).each do |afi|
      ['eq 2', 'neq 2', 'gt 2', 'lt 2',
       'portgroup my_pg'].each do |val|
        a = ace_helper(afi, src_port: val, dst_port: val)
        assert_equal(val, a.src_port)
        assert_equal(val, a.dst_port)
      end
    end
  end

  def test_dscp
    %w(ipv4 ipv6).each do |afi|
      %w(5 60 af11 af12 af13 af21 af22 af23 af31 af32 af33 af41 af42 af43
         cs1 cs2 cs3 cs4 cs5 cs6 cs7 default ef).each do |val|
        a = ace_helper(afi, dscp: val)
        assert_equal(val, a.dscp)
      end
    end
  end

  def test_tcp_flags
    %w(ipv4 ipv6).each do |afi|
      %w(ack fin urg syn psh rst) + [
        'ack fin', 'ack psh rst'].each do |val|
        a = ace_helper(afi, tcp_flags: val)
        assert_equal(val, a.tcp_flags)
      end
    end
  end

  def test_established
    %w(ipv4 ipv6).each do |afi|
      refute(ace_helper(afi).established)
      a = ace_helper(afi, established: true)
      assert(a.established)
      a = ace_helper(afi, established: false)
      refute(a.established)
    end
  end

  def test_http_method
    afi = 'ipv4'
    %w(connect delete get head post put trace).each do |val|
      a = ace_helper(afi, http_method: val)
      assert_equal(val, a.http_method)
    end
  end

  def test_log
    %w(ipv4 ipv6).each do |afi|
      refute(ace_helper(afi).log)
      a = ace_helper(afi, log: true)
      assert(a.log)
      a = ace_helper(afi, log: false)
      refute(a.log)
    end
  end

  def test_precedence
    afi = 'ipv4'
    %w(critical flash flash-override immediate internet network
       priority routine).each do |val|
      a = ace_helper(afi, precedence: val)
      assert_equal(val, a.precedence)
    end
  end

  def test_redirect
    afi = 'ipv4'
    val = 'port-channel1,port-channel2'
    a = ace_helper(afi, redirect: val)
    assert_equal(val, a.redirect)
  end

  def test_tcp_option_length
    afi = 'ipv4'
    %w(0 16 28).each do |val|
      a = ace_helper(afi, tcp_option_length: val)
      assert_equal(val, a.tcp_option_length)
    end
  end

  def test_time_range
    val = 'my_range'
    %w(ipv4 ipv6).each do |afi|
      a = ace_helper(afi, time_range: val)
      assert_equal(val, a.time_range)
    end
  end

  def test_packet_length
    val = 'range 80 1000'
    %w(ipv4 ipv6).each do |afi|
      a = ace_helper(afi, packet_length: val)
      assert_equal(val, a.packet_length)
    end
  end

  def test_ttl
    val = '3'
    %w(ipv4 ipv6).each do |afi|
      a = ace_helper(afi, ttl: val)
      skip("This property has a known defect on the platform itself -\n"\
           'CSCuy47463: access-list ttl does not nvgen') if a.ttl.nil?
      assert_equal(val, a.ttl)
    end
  end
end
