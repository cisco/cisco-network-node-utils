# Copyright (c) 2015 Cisco and/or its affiliates.
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
require_relative '../lib/cisco_node_utils/vpc'

include Cisco

# TestVpc - Minitest for Vpc node utility class
class TestVpc < CiscoTestCase
  def setup
    super
    no_feature_vpc
  end

  def teardown
    no_feature_vpc
    super
  end

  def no_feature_vpc
    config('terminal dont-ask ; no feature vpc')
  end

  def n5k6k_platforms?
    /N[56]K/ =~ node.product_id
  end

  def n3k9k_platforms?
    /N[39]K/ =~ node.product_id
  end

  # TESTS

  def test_vpc_collection_empty
    assert(Vpc.domains.empty?,
           'Domain collection should be empty for this test')
  end

  def test_vpc_create
    @vpc = Vpc.new(100)
    assert(@vpc.domain == 100,
           "VPC domain not set correctly #{@vpc.domain}")
    assert(Vpc.enabled,
           'VPC feature should have been enabled')
    refute(Vpc.domains.empty?,
           'Domain collection should not be empty after create')
  end

  def test_vpc_create_negative
    e = assert_raises(CliError) { Vpc.new(1001) }
    assert_match(/Invalid number.*range/, e.message)
  end

  def test_vpc_destroy
    # create and test again
    test_vpc_create
    @vpc.destroy
    # now it should be wiped out
    test_vpc_collection_empty
  end

  def test_auto_recovery
    @vpc = Vpc.new(100)
    assert(@vpc.auto_recovery, 'Auto recovery should be enabled by default')
    @vpc.auto_recovery = false
    refute(@vpc.auto_recovery, 'Auto recovery not getting disabled')
    @vpc.auto_recovery = true
    assert(@vpc.auto_recovery, 'Auto recovery not getting set')
  end

  def test_auto_recovery_delay
    @vpc = Vpc.new(100)
    default_value = @vpc.default_auto_recovery
    assert_equal(default_value, @vpc.auto_recovery,
                 "Auto recovery delay should be #{default_value}")
    @vpc.auto_recovery_reload_delay = 200
    assert_equal(200, @vpc.auto_recovery_reload_delay,
                 "Auto recovery delay should be 200")
  end

  def test_auto_recovery_delay
    @vpc = Vpc.new(100)
    default_value = @vpc.default_auto_recovery
    assert_equal(default_value, @vpc.auto_recovery,
                 "Auto recovery delay should be #{default_value}")
    @vpc.auto_recovery_reload_delay = 200
    assert_equal(200, @vpc.auto_recovery_reload_delay,
                 "Auto recovery delay should be 200")
  end



end
