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

  #def n5k6k_platforms?
  #  /N[56]K/ =~ node.product_id
  #end

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

  def test_vpc_destroy
    # create and test again
    test_vpc_create
    @vpc.destroy
    # now it should be wiped out
    test_vpc_collection_empty
  end

end
