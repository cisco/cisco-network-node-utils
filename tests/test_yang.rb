#!/usr/bin/env ruby
# Yang Unit Tests
#
# Charles Burkett, May, 2016
#
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
require_relative '../lib/cisco_node_utils/yang'

# TestYang - Minitest for Yang class
class TestYang < CiscoTestCase
  BLUE_VRF = '{"Cisco-IOS-XR-infra-rsi-cfg:vrfs":{
      "vrf":[
         {
            "vrf-name":"BLUE",
            "description":"Generic external traffic",
            "create":[
               null
            ]
         }
      ]
    }}'

  RED_VRF = '{"Cisco-IOS-XR-infra-rsi-cfg:vrfs":{
      "vrf":[
         {
            "vrf-name":"RED",
            "create":[
               null
            ]
         }
      ]
    }}'

  GREEN_VRF = '{"Cisco-IOS-XR-infra-rsi-cfg:vrfs":{
      "vrf":[
         {
            "vrf-name":"GREEN",
            "create": [null]
         }
      ]
    }}'

  BLUE_GREEN_VRF = '{"Cisco-IOS-XR-infra-rsi-cfg:vrfs":{
      "vrf":[
         {
            "vrf-name":"BLUE",
            "create":[null],
            "description":"Generic external traffic"
         },
         {
            "vrf-name":"GREEN",
            "create":[null]
         }
      ]
  }}'

  BLUE_VRF_NO_PROPERTIES = '{"Cisco-IOS-XR-infra-rsi-cfg:vrfs":{
      "vrf":[
         {
            "vrf-name":"BLUE",
            "create":[
               null
            ]
         }
      ]
    }}'

  BLUE_VRF_PROPERTIES1 = '{"Cisco-IOS-XR-infra-rsi-cfg:vrfs":{
      "vrf":[
         {
            "vrf-name":"BLUE",
            "create":[
               null
            ],
            "vpn-id":{
              "vpn-oui":0,
              "vpn-index":0
              }
         }
      ]
    }}'

  BLUE_VRF_PROPERTIES2 = '{"Cisco-IOS-XR-infra-rsi-cfg:vrfs":{
      "vrf":[
         {
            "vrf-name":"BLUE",
            "description":"Generic external traffic",
            "create":[
               null
            ],
            "vpn-id":{
              "vpn-oui":0,
              "vpn-index":0
              }
         }
      ]
    }}'

  BLUE_VRF_PROPERTIES3 = '{"Cisco-IOS-XR-infra-rsi-cfg:vrfs":{
      "vrf":[
         {
            "vrf-name":"BLUE",
            "description":"Generic ext traffic",
            "create":[
               null
            ],
            "vpn-id":{
              "vpn-oui":8,
              "vpn-index":9
              }
         }
      ]
    }}'

  NO_VRFS = '{"Cisco-IOS-XR-infra-rsi-cfg:vrfs": [null]}'
  PATH_VRFS = '{"Cisco-IOS-XR-infra-rsi-cfg:vrfs": [null]}'

  def self.runnable_methods
    return [:all_skipped] unless platform == :ios_xr
    super
  end

  def all_skipped
    puts 'Node under test does not appear to use the gRPC client'
    assert(validate_property_excluded?('yang', 'support'))
  end

  def setup
    super
    clear_vrfs
  end

  def teardown
    super
    clear_vrfs
  end

  def clear_vrfs
    return unless platform == :ios_xr
    current_vrfs = node.get_yang(PATH_VRFS)

    # remove all vrfs
    node.delete_yang(PATH_VRFS) unless Yang.empty?(current_vrfs)
  end

  def test_delete_vrfs
    node.merge_yang(BLUE_VRF)  # ensure at least one VRF is there
    assert(node.get_yang(PATH_VRFS).match('BLUE'), 'Did not find the BLUE vrf')

    clear_vrfs
    assert_equal('', node.get_yang(PATH_VRFS),
                 'There are still vrfs configured')
  end

  def test_add_vrf
    node.merge_yang(BLUE_VRF)  # create a single VRF
    assert(node.get_yang(PATH_VRFS).match('BLUE'), 'Did not find the BLUE vrf')

    node.replace_yang(GREEN_VRF) # create a single VRF
    assert(node.get_yang(PATH_VRFS).match('GREEN'),
           'Did not find the GREEN vrf')
    refute(node.get_yang(PATH_VRFS).match('BLUE'),
           'Found the BLUE vrf')
  end

  def test_errors
    # Note: Originally, we were checking for YangErrors and ClientErrors,
    # but the type of error raised seemed to change from one XR image to the
    # next, so now we check for the more general CiscoError in these tests.

    # === test get_yang ===========

    # Request is not wellformed
    assert_raises(Cisco::CiscoError) { node.get_yang('aabbcc') }

    # parse error: object key and value must be separated by a colon
    assert_raises(Cisco::CiscoError) { node.get_yang('{"aabbcc"}') }

    # unknown-namespace
    assert_raises(Cisco::CiscoError) { node.get_yang('{"aabbcc": "foo"}') }

    # unknown-element
    assert_raises(Cisco::CiscoError) do
      node.get_yang('{"Cisco-IOS-XR-infra-rsi-cfg:aabbcc": "foo"}')
    end

    # parse error: premature EOF
    assert_raises(Cisco::CiscoError) { node.get_yang('{') }

    # parse error: invalid object key (must be a string)
    assert_raises(Cisco::CiscoError) { node.get_yang('{: "foo"}') }

    # === test merge_yang ===========

    # Request is not wellformed
    assert_raises(Cisco::CiscoError) { node.merge_yang('aabbcc') }

    # unknown-element
    assert_raises(Cisco::CiscoError) do
      node.merge_yang('{"Cisco-IOS-XR-infra-rsi-cfg:aabbcc": "foo"}')
    end

    # bad-element
    assert_raises(Cisco::CiscoError) do
      node.merge_yang('{"Cisco-IOS-XR-infra-rsi-cfg:vrfs": "foo"}')
    end

    # missing-element
    assert_raises(Cisco::CiscoError) do
      node.merge_yang('{"Cisco-IOS-XR-infra-rsi-cfg:vrfs": {"vrf":[{}]}}')
    end

    # === test replace_yang ===========

    # unknown-namespace
    assert_raises(Cisco::CiscoError) do
      node.replace_yang('{"Cisco-IOS-XR-infra-rsi-cfg:aabbcc": "foo"}')
    end

    # Request is not wellformed
    assert_raises(Cisco::CiscoError) do
      node.replace_yang('{"Cisco-IOS-XR-infra-rsi-cfg:vrfs": }')
    end
  end

  def test_merge_diff
    # ensure we think that a merge is needed (in-sinc = false)
    refute(Yang.insync_for_merge?(BLUE_VRF, node.get_yang(PATH_VRFS)),
           'Expected not in-sync')

    node.merge_yang(BLUE_VRF) # create the blue VRF

    # ensure we think that a merge is NOT needed (in-sinc = true)
    assert(Yang.insync_for_merge?(BLUE_VRF, node.get_yang(PATH_VRFS)),
           'Expected in-sync')

    # ensure we think that the merge is needed (in-sinc = false)
    refute(Yang.insync_for_merge?(RED_VRF, node.get_yang(PATH_VRFS)),
           'Expected not in-sync')

    node.merge_yang(RED_VRF) # create the red VRF

    # ensure we think that a merge is NOT needed (in-sinc = true)
    assert(Yang.insync_for_merge?(RED_VRF, node.get_yang(PATH_VRFS)),
           'Expected in-sync')

    node.merge_yang(GREEN_VRF) # create green VRF
    # ensure we think that a merge is NOT needed (in-sinc = true)
    assert(Yang.insync_for_merge?(GREEN_VRF, node.get_yang(PATH_VRFS)),
           'Expected in-sync')
  end

  def test_replace_diff
    # ensure we think that a merge is needed (in-sinc = false)
    refute(Yang.insync_for_replace?(BLUE_VRF, node.get_yang(PATH_VRFS)),
           'Expected not in-sync')

    node.replace_yang(BLUE_VRF) # create the blue VRF
    # ensure we think that a replace is NOT needed (in-sinc = true)
    assert(Yang.insync_for_replace?(BLUE_VRF, node.get_yang(PATH_VRFS)),
           'Expected in-sync')

    node.replace_yang(RED_VRF) # create the red VRF
    # ensure we think that a replace is NOT needed (in-sinc = true)
    assert(Yang.insync_for_replace?(RED_VRF, node.get_yang(PATH_VRFS)),
           'Expected in-sync')

    node.replace_yang(GREEN_VRF) # create green VRF
    # ensure we think that a replace is NOT needed (in-sinc = true)
    assert(Yang.insync_for_replace?(GREEN_VRF, node.get_yang(PATH_VRFS)),
           'Expected in-sync')

    node.merge_yang(BLUE_VRF)

    # ensure we think that a replace is NOT needed (in-sinc = true)
    assert(Yang.insync_for_replace?(BLUE_GREEN_VRF, node.get_yang(PATH_VRFS)),
           'Expected in sync')
    # ensure we think that a replace is needed (in-sinc = true)
    refute(Yang.insync_for_replace?(BLUE_VRF, node.get_yang(PATH_VRFS)),
           'Expected not in sync')
    refute(Yang.insync_for_replace?(GREEN_VRF, node.get_yang(PATH_VRFS)),
           'Expected not in sync')

    node.replace_yang(BLUE_VRF)
    # ensure we think that a replace is NOT needed (in-sinc = true)
    assert(Yang.insync_for_replace?(BLUE_VRF, node.get_yang(PATH_VRFS)),
           'Expected in-sync')
    # ensure we think that a replace is needed (in-sinc = true)
    refute(Yang.insync_for_replace?(GREEN_VRF, node.get_yang(PATH_VRFS)),
           'Expected not in-sync')
    refute(Yang.insync_for_replace?(BLUE_GREEN_VRF, node.get_yang(PATH_VRFS)),
           'Expected not in-sync')
  end

  def test_merge_leaves
    node.merge_yang(BLUE_VRF) # create blue vrf with description

    # merge blue vrf with vpn id to blue vrf with description
    node.merge_yang(BLUE_VRF_PROPERTIES1)

    # ensure that new leaves are merged with old.
    assert(Yang.insync_for_merge?(BLUE_VRF_PROPERTIES2,
                                  node.get_yang(PATH_VRFS)), 'Expected in-sync')

    # update description and vpn-id
    node.merge_yang(BLUE_VRF_PROPERTIES3)
    assert(Yang.insync_for_merge?(BLUE_VRF_PROPERTIES3,
                                  node.get_yang(PATH_VRFS)), 'Expected in-sync')
  end

  def test_replace_leaves
    node.replace_yang(BLUE_VRF) # create blue vrf with description

    # replace blue vrf (description) by blue vrf (vpn-id)
    node.replace_yang(BLUE_VRF_PROPERTIES1)

    # ensure that new properties are replaced by old.
    assert(Yang.insync_for_replace?(BLUE_VRF_PROPERTIES1,
                                    node.get_yang(PATH_VRFS)),
           'Expected in-sync')

    # replace description and vpn-id
    node.replace_yang(BLUE_VRF_PROPERTIES3)
    assert(Yang.insync_for_replace?(BLUE_VRF_PROPERTIES3,
                                    node.get_yang(PATH_VRFS)),
           'Expected in-sync')
  end

  def test_merge
    node.merge_yang(BLUE_VRF)   # create blue vrf
    node.merge_yang(GREEN_VRF)  # create green vrf

    yang = node.get_yang(PATH_VRFS)

    assert_yang_equal(BLUE_GREEN_VRF, yang)
  end

  def test_replace
    node.merge_yang(BLUE_VRF)     # create blue vrf
    node.replace_yang(GREEN_VRF)  # create green vrf

    yang = node.get_yang(PATH_VRFS)

    assert_yang_equal(GREEN_VRF, yang)
  end

  def assert_yang_equal(expected, actual)
    equal = Yang.insync_for_replace?(expected, actual) &&
            Yang.insync_for_replace?(actual, expected)
    assert(equal,
           "Expected: '#{expected}',\n"\
           "Actual: '#{actual}',\n",
          )
  end
end
