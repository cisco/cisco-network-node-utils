#
# Minitest for Banner class
#
# Copyright (c) 2014-2018 Cisco and/or its affiliates.
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
require_relative '../lib/cisco_node_utils/banner'

# TestBanner - Minitest for Banner node utility.
class TestBanner < CiscoTestCase
  def setup
    # setup runs at the beginning of each test
    super
    no_motd
  end

  def teardown
    # teardown runs at the end of each test
    no_motd
    super
  end

  def no_motd
    # Turn the feature off for a clean test.
    config('no banner motd')
  end

  # TESTS

  def test_single_motd
    id = 'default'

    banner = Cisco::Banner.new(id)
    assert_includes(Cisco::Banner.banners, id)
    assert_equal(Cisco::Banner.banners[id], banner)

    assert_equal(banner.default_motd, Cisco::Banner.banners['default'].motd)
    assert_equal(banner.default_motd, banner.motd)

    banner.motd = 'Test banner!'
    assert_equal(Cisco::Banner.banners['default'].motd,
                 'Test banner!')
    assert_equal(Cisco::Banner.banners['default'].motd,
                 banner.motd)

    banner.motd = nil
    assert_equal(banner.default_motd, Cisco::Banner.banners['default'].motd)
    assert_equal(banner.default_motd, banner.motd)
  end

  def test_multiline_motd
    skip_versions = ['7.0.3.I[2-6]', '7.0.3.I7.[1-3]', '7.3', '8.[1-3]']
    skip_legacy_defect?(skip_versions, 'multiline banner configuration using nxapi not supported')
    id = 'default'

    banner = Cisco::Banner.new(id)
    assert_includes(Cisco::Banner.banners, id)
    assert_equal(Cisco::Banner.banners[id], banner)

    assert_equal(banner.default_motd, Cisco::Banner.banners['default'].motd)
    assert_equal(banner.default_motd, banner.motd)

    banner.motd = 'This is\na sweet\n\nmultiline\nbanner!\n'
    assert_equal(Cisco::Banner.banners['default'].motd,
                 "This is\na sweet\n\nmultiline\nbanner!\n")
    assert_equal(Cisco::Banner.banners['default'].motd,
                 banner.motd)

    banner.motd = nil
    assert_equal(banner.default_motd, Cisco::Banner.banners['default'].motd)
    assert_equal(banner.default_motd, banner.motd)
  end
end
