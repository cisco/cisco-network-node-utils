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
require_relative '../lib/cisco_node_utils/stp_global'

# TestX__CLASS_NAME__X - Minitest for X__CLASS_NAME__X node utility class
class TestStpGlobal < CiscoTestCase
  # TESTS

  DEFAULT_NAME = 'default'

  def setup
    super
  end

  def teardown
    super
  end

  def n7k_platform?
    /N7/ =~ node.product_id
  end

  def n9k_platform?
    /N(3|9)/ =~ node.product_id
  end

  def n6k_platform?
    /N(5|6)/ =~ node.product_id
  end

  def create_stp_global(name=DEFAULT_NAME)
    StpGlobal.new(name)
  end

  def test_get_set_bpdufilter
    @global = create_stp_global
    @global.bpdufilter = true
    assert_equal(true, @global.bpdufilter)
    @global.bpdufilter =
      @global.default_bpdufilter
    assert_equal(@global.default_bpdufilter,
                 @global.bpdufilter)
  end

  def test_get_set_bpduguard
    @global = create_stp_global
    @global.bpduguard = true
    assert_equal(true, @global.bpduguard)
    @global.bpduguard =
      @global.default_bpduguard
    assert_equal(@global.default_bpduguard,
                 @global.bpduguard)
  end

  def test_get_set_bridge_assurance
    @global = create_stp_global
    @global.bridge_assurance = false
    assert_equal(false, @global.bridge_assurance)
    @global.bridge_assurance =
      @global.default_bridge_assurance
    assert_equal(@global.default_bridge_assurance,
                 @global.bridge_assurance)
  end

  def test_get_set_domain
    skip('Platform does not support this property') if n9k_platform?
    @global = create_stp_global
    @global.domain = 100
    assert_equal(100, @global.domain)
    @global.domain =
      @global.default_domain
    assert_equal(@global.default_domain,
                 @global.domain)
    @global.domain =
      @global.default_domain
    assert_equal(@global.default_domain,
                 @global.domain)
  end

  def test_get_set_fcoe
    skip('Platform does not support this property') if n6k_platform? ||
                                                       n7k_platform?
    @global = create_stp_global
    @global.fcoe = false
    assert_equal(false, @global.fcoe)
    @global.fcoe =
      @global.default_fcoe
    assert_equal(@global.default_fcoe,
                 @global.fcoe)
  end

  def test_get_set_loopguard
    @global = create_stp_global
    @global.loopguard = true
    assert_equal(true, @global.loopguard)
    @global.loopguard =
      @global.default_loopguard
    assert_equal(@global.default_loopguard,
                 @global.loopguard)
  end

  def test_get_set_mode
    @global = create_stp_global
    @global.mode = 'mst'
    assert_equal('mst', @global.mode)
    @global.mode =
      @global.default_mode
    assert_equal(@global.default_mode,
                 @global.mode)
  end

  def test_get_set_pathcost
    @global = create_stp_global
    @global.pathcost = 'long'
    assert_equal('long', @global.pathcost)
    @global.pathcost =
      @global.default_pathcost
    assert_equal(@global.default_pathcost,
                 @global.pathcost)
  end
end
