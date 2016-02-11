#
# Minitest for DomainName class
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
require_relative '../lib/cisco_node_utils/domain_name'

# TestDomainName - Minitest for DomainName node utility.
class TestDomainName < CiscoTestCase
  def setup
    # setup runs at the beginning of each test
    super
    no_domainname_test_xyz
  end

  def teardown
    # teardown runs at the end of each test
    no_domainname_test_xyz
    super
  end

  def no_domainname_test_xyz
    # Turn the feature off for a clean test.
    config('no ip domain-name test.abc',
           'no ip domain-name test.xyz',
           'no vrf context test')
  end

  # TESTS

  def test_domainname_create_replace_destroy
    name1 = 'test.abc'
    name2 = 'test.xyz'
    refute_includes(Cisco::DomainName.domainnames, name1)
    refute_includes(Cisco::DomainName.domainnames, name2)

    domain = Cisco::DomainName.new(name1)
    assert_includes(Cisco::DomainName.domainnames, name1)
    refute_includes(Cisco::DomainName.domainnames, name2)
    assert_equal(Cisco::DomainName.domainnames[name1], domain)

    domain = Cisco::DomainName.new(name2)
    refute_includes(Cisco::DomainName.domainnames, name1)
    assert_includes(Cisco::DomainName.domainnames, name2)
    assert_equal(Cisco::DomainName.domainnames[name2], domain)

    domain.destroy
    refute_includes(Cisco::DomainName.domainnames, name1)
    refute_includes(Cisco::DomainName.domainnames, name2)
  end

  def test_domainname_create_replace_destroy_vrf
    name1 = 'test.abc'
    name2 = 'test.xyz'
    vrf = 'test'
    refute_includes(Cisco::DomainName.domainnames(vrf), name1)
    refute_includes(Cisco::DomainName.domainnames(vrf), name2)

    domain = Cisco::DomainName.new(name1, vrf)
    assert_includes(Cisco::DomainName.domainnames(vrf), name1)
    refute_includes(Cisco::DomainName.domainnames(vrf), name2)
    assert_equal(Cisco::DomainName.domainnames(vrf)[name1], domain)

    domain = Cisco::DomainName.new(name2, vrf)
    refute_includes(Cisco::DomainName.domainnames(vrf), name1)
    assert_includes(Cisco::DomainName.domainnames(vrf), name2)
    assert_equal(Cisco::DomainName.domainnames(vrf)[name2], domain)

    domain.destroy
    refute_includes(Cisco::DomainName.domainnames(vrf), name1)
    refute_includes(Cisco::DomainName.domainnames(vrf), name2)
  end
end
