#
# Minitest for DnsDomain class
#
# Copyright (c) 2014-2016 Cisco and/or its affiliates.
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
require_relative '../lib/cisco_node_utils/dns_domain'

# TestDnsDomain - Minitest for DnsDomain node utility.
class TestDnsDomain < CiscoTestCase
  def setup
    # setup runs at the beginning of each test
    super
    no_dnsdomain_tests
  end

  def teardown
    # teardown runs at the end of each test
    no_dnsdomain_tests
    super
  end

  def no_dnsdomain_tests
    # Turn the feature off for a clean test.
    config('no ip domain-list aoeu.com',
           'no ip domain-list asdf.com',
           'no vrf context test')
  end

  # TESTS

  def test_dnsdomain_create_destroy_single
    id = 'aoeu.com'
    refute_includes(Cisco::DnsDomain.dnsdomains, id)

    ns = Cisco::DnsDomain.new(id)
    assert_includes(Cisco::DnsDomain.dnsdomains, id)
    assert_equal(Cisco::DnsDomain.dnsdomains[id], ns)

    ns.destroy
    refute_includes(Cisco::DnsDomain.dnsdomains, id)
  end

  def test_dnsdomain_create_destroy_multiple
    id1 = 'aoeu.com'
    id2 = 'asdf.com'
    refute_includes(Cisco::DnsDomain.dnsdomains, id1)
    refute_includes(Cisco::DnsDomain.dnsdomains, id2)

    ns1 = Cisco::DnsDomain.new(id1)
    ns2 = Cisco::DnsDomain.new(id2)
    assert_includes(Cisco::DnsDomain.dnsdomains, id1)
    assert_includes(Cisco::DnsDomain.dnsdomains, id2)
    assert_equal(Cisco::DnsDomain.dnsdomains[id1], ns1)
    assert_equal(Cisco::DnsDomain.dnsdomains[id2], ns2)

    ns1.destroy
    refute_includes(Cisco::DnsDomain.dnsdomains, id1)
    assert_includes(Cisco::DnsDomain.dnsdomains, id2)
    ns2.destroy
    refute_includes(Cisco::DnsDomain.dnsdomains, id2)
  end

  def test_dnsdomain_create_destroy_single_vrf
    id = 'aoeu.com'
    vrf = 'test'
    non_vrf = Cisco::DnsDomain.new(id)
    assert_includes(Cisco::DnsDomain.dnsdomains, id)
    refute_includes(Cisco::DnsDomain.dnsdomains(vrf), id)

    ns = Cisco::DnsDomain.new(id, vrf)
    assert_includes(Cisco::DnsDomain.dnsdomains(vrf), id)
    assert_equal(Cisco::DnsDomain.dnsdomains(vrf)[id], ns)

    ns.destroy
    refute_includes(Cisco::DnsDomain.dnsdomains(vrf), id)
    assert_includes(Cisco::DnsDomain.dnsdomains, id)
    non_vrf.destroy
  end

  def test_dnsdomain_create_destroy_multiple_vrf
    id1 = 'aoeu.com'
    id2 = 'asdf.com'
    vrf = 'test'
    refute_includes(Cisco::DnsDomain.dnsdomains(vrf), id1)
    refute_includes(Cisco::DnsDomain.dnsdomains(vrf), id2)

    ns1 = Cisco::DnsDomain.new(id1, vrf)
    ns2 = Cisco::DnsDomain.new(id2, vrf)
    assert_includes(Cisco::DnsDomain.dnsdomains(vrf), id1)
    assert_includes(Cisco::DnsDomain.dnsdomains(vrf), id2)
    assert_equal(Cisco::DnsDomain.dnsdomains(vrf)[id1], ns1)
    assert_equal(Cisco::DnsDomain.dnsdomains(vrf)[id2], ns2)

    ns1.destroy
    refute_includes(Cisco::DnsDomain.dnsdomains(vrf), id1)
    assert_includes(Cisco::DnsDomain.dnsdomains(vrf), id2)
    ns2.destroy
    refute_includes(Cisco::DnsDomain.dnsdomains(vrf), id2)
  end
end
