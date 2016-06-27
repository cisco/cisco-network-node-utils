# Copyright (c) 2016 Cisco and/or its affiliates.
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
require_relative '../lib/cisco_node_utils/router_ospf'
require_relative '../lib/cisco_node_utils/router_ospf_vrf'
require_relative '../lib/cisco_node_utils/router_ospf_area_vlink'

# TestRouterOspfAreaVirtualLink - Minitest for RouterOspfAreaVirtualLink
# node utility class
class TestRouterOspfAreaVirtualLink < CiscoTestCase
  @skip_unless_supported = 'ospf_area_vlink'
  @@pre_clean_needed = true # rubocop:disable Style/ClassVars

  def setup
    super
    remove_all_ospfs if @@pre_clean_needed
    @@pre_clean_needed = false # rubocop:disable Style/ClassVars
  end

  def teardown
    remove_all_ospfs
    super
  end

  def create_routerospfarea_default_virtual_link(router='Wolfpack',
                                                 name='default',
                                                 area_id='1.1.1.1',
                                                 vl='2.2.2.2')
    RouterOspfAreaVirtualLink.new(router, name, area_id, vl)
  end

  def create_routerospfarea_vrf_virtual_link(router='Wolfpack',
                                             name='blue',
                                             area_id='1450',
                                             vl='3.3.3.3')
    RouterOspfAreaVirtualLink.new(router, name, area_id, vl)
  end

  def test_collection_size
    dvl1 = create_routerospfarea_default_virtual_link
    assert_equal(1, RouterOspfAreaVirtualLink.virtual_links['Wolfpack']['default']['1.1.1.1'].size)
    dvl2 = create_routerospfarea_default_virtual_link('Wolfpack', 'default', '1.1.1.1', '5.5.5.5')
    assert_equal(2, RouterOspfAreaVirtualLink.virtual_links['Wolfpack']['default']['1.1.1.1'].size)
    dvl3 = create_routerospfarea_default_virtual_link('Wolfpack', 'default', '6.6.6.6', '5.5.5.5')
    assert_equal(1, RouterOspfAreaVirtualLink.virtual_links['Wolfpack']['default']['6.6.6.6'].size)
    vvl1 = create_routerospfarea_vrf_virtual_link
    assert_equal(1, RouterOspfAreaVirtualLink.virtual_links['Wolfpack']['blue']['0.0.5.170'].size)
    vvl2 = create_routerospfarea_vrf_virtual_link('Wolfpack', 'blue', '1000', '5.5.5.5')
    assert_equal(1, RouterOspfAreaVirtualLink.virtual_links['Wolfpack']['blue']['0.0.3.232'].size)
    vvl3 = create_routerospfarea_vrf_virtual_link('Wolfpack', 'red', '1000', '5.5.5.5')
    assert_equal(1, RouterOspfAreaVirtualLink.virtual_links['Wolfpack']['red']['0.0.3.232'].size)
    vvl4 = create_routerospfarea_vrf_virtual_link('Wolfpack', 'red', '2000', '5.5.5.5')
    assert_equal(1, RouterOspfAreaVirtualLink.virtual_links['Wolfpack']['red']['0.0.7.208'].size)
    vvl5 = create_routerospfarea_vrf_virtual_link('Wolfpack', 'red', '2000', '2.2.2.2')
    assert_equal(2, RouterOspfAreaVirtualLink.virtual_links['Wolfpack']['red']['0.0.7.208'].size)
    dvl1.destroy
    dvl2.destroy
    dvl3.destroy
    vvl1.destroy
    vvl2.destroy
    vvl3.destroy
    vvl4.destroy
    vvl5.destroy
    assert_empty(RouterOspfAreaVirtualLink.virtual_links)
  end

  def test_dead_interval
    dvl = create_routerospfarea_default_virtual_link
    assert_equal(dvl.default_dead_interval, dvl.dead_interval)
    dvl.dead_interval = 500
    assert_equal(500, dvl.dead_interval)
    dvl.dead_interval = dvl.default_dead_interval
    assert_equal(dvl.default_dead_interval, dvl.dead_interval)
    vvl = create_routerospfarea_vrf_virtual_link
    assert_equal(vvl.default_dead_interval, vvl.dead_interval)
    vvl.dead_interval = 1000
    assert_equal(1000, vvl.dead_interval)
    vvl.dead_interval = vvl.default_dead_interval
    assert_equal(vvl.default_dead_interval, vvl.dead_interval)
  end

  def test_hello_interval
    dvl = create_routerospfarea_default_virtual_link
    assert_equal(dvl.default_hello_interval, dvl.hello_interval)
    dvl.hello_interval = 1500
    assert_equal(1500, dvl.hello_interval)
    dvl.hello_interval = dvl.default_hello_interval
    assert_equal(dvl.default_hello_interval, dvl.hello_interval)
    vvl = create_routerospfarea_vrf_virtual_link
    assert_equal(vvl.default_hello_interval, vvl.hello_interval)
    vvl.hello_interval = 2000
    assert_equal(2000, vvl.hello_interval)
    vvl.hello_interval = vvl.default_hello_interval
    assert_equal(vvl.default_hello_interval, vvl.hello_interval)
  end

  def test_retransmit_interval
    dvl = create_routerospfarea_default_virtual_link
    assert_equal(dvl.default_retransmit_interval, dvl.retransmit_interval)
    dvl.retransmit_interval = 200
    assert_equal(200, dvl.retransmit_interval)
    dvl.retransmit_interval = dvl.default_retransmit_interval
    assert_equal(dvl.default_retransmit_interval, dvl.retransmit_interval)
    vvl = create_routerospfarea_vrf_virtual_link
    assert_equal(vvl.default_retransmit_interval, vvl.retransmit_interval)
    vvl.retransmit_interval = 10_000
    assert_equal(10_000, vvl.retransmit_interval)
    vvl.retransmit_interval = vvl.default_retransmit_interval
    assert_equal(vvl.default_retransmit_interval, vvl.retransmit_interval)
  end

  def test_transmit_delay
    dvl = create_routerospfarea_default_virtual_link
    assert_equal(dvl.default_transmit_delay, dvl.transmit_delay)
    dvl.transmit_delay = 250
    assert_equal(250, dvl.transmit_delay)
    dvl.transmit_delay = dvl.default_transmit_delay
    assert_equal(dvl.default_transmit_delay, dvl.transmit_delay)
    vvl = create_routerospfarea_vrf_virtual_link
    assert_equal(vvl.default_transmit_delay, vvl.transmit_delay)
    vvl.transmit_delay = 400
    assert_equal(400, vvl.transmit_delay)
    vvl.transmit_delay = vvl.default_transmit_delay
    assert_equal(vvl.default_transmit_delay, vvl.transmit_delay)
  end

  def test_auth_key_chain
    dvl = create_routerospfarea_default_virtual_link
    assert_equal(dvl.default_auth_key_chain, dvl.auth_key_chain)
    dvl.auth_key_chain = 'testing123'
    assert_equal('testing123', dvl.auth_key_chain)
    dvl.auth_key_chain = dvl.default_auth_key_chain
    assert_equal(dvl.default_auth_key_chain, dvl.auth_key_chain)
    vvl = create_routerospfarea_vrf_virtual_link
    assert_equal(vvl.default_auth_key_chain, vvl.auth_key_chain)
    vvl.auth_key_chain = 'awesome'
    assert_equal('awesome', vvl.auth_key_chain)
    vvl.auth_key_chain = vvl.default_auth_key_chain
    assert_equal(vvl.default_auth_key_chain, vvl.auth_key_chain)
  end

  def test_authentication
    dvl = create_routerospfarea_default_virtual_link
    assert_equal(dvl.default_authentication, dvl.authentication)
    dvl.authentication = 'md5'
    assert_equal('md5', dvl.authentication)
    dvl.authentication = 'cleartext'
    assert_equal('cleartext', dvl.authentication)
    dvl.authentication = 'null'
    assert_equal('null', dvl.authentication)
    dvl.authentication = dvl.default_authentication
    assert_equal(dvl.default_authentication, dvl.authentication)
    vvl = create_routerospfarea_vrf_virtual_link
    assert_equal(vvl.default_authentication, vvl.authentication)
    vvl.authentication = 'md5'
    assert_equal('md5', vvl.authentication)
    vvl.authentication = 'cleartext'
    assert_equal('cleartext', vvl.authentication)
    vvl.authentication = 'null'
    assert_equal('null', vvl.authentication)
    vvl.authentication = vvl.default_authentication
    assert_equal(vvl.default_authentication, vvl.authentication)
  end

  def test_authentication_key
    dvl = create_routerospfarea_default_virtual_link
    assert_equal(dvl.default_authentication_key_encryption_type,
                 dvl.authentication_key_encryption_type)
    assert_equal(dvl.default_authentication_key_password,
                 dvl.authentication_key_password)
    encr = :"3des"
    encr_pw = '762bc328e3bdf235'
    dvl.authentication_key_set(encr, encr_pw)
    assert_equal(encr, dvl.authentication_key_encryption_type)
    assert_equal(encr_pw, dvl.authentication_key_password)
    encr = :cisco_type_7
    encr_pw = '12345678901234567890'
    dvl.authentication_key_set(encr, encr_pw)
    assert_equal(encr, dvl.authentication_key_encryption_type)
    assert_equal(encr_pw, dvl.authentication_key_password)
    dvl.authentication_key_set(dvl.default_authentication_key_encryption_type,
                               dvl.default_authentication_key_password)
    assert_equal(dvl.default_authentication_key_encryption_type,
                 dvl.authentication_key_encryption_type)
    assert_equal(dvl.default_authentication_key_password,
                 dvl.authentication_key_password)
    vvl = create_routerospfarea_vrf_virtual_link
    assert_equal(vvl.default_authentication_key_encryption_type,
                 vvl.authentication_key_encryption_type)
    assert_equal(vvl.default_authentication_key_password,
                 vvl.authentication_key_password)
    encr = :"3des"
    encr_pw = '1347c56888deb142'
    vvl.authentication_key_set(encr, encr_pw)
    assert_equal(encr, vvl.authentication_key_encryption_type)
    assert_equal(encr_pw, vvl.authentication_key_password)
    encr = :cisco_type_7
    encr_pw = '046E1803362E595C260E0B240619050A2D'
    vvl.authentication_key_set(encr, encr_pw)
    assert_equal(encr, vvl.authentication_key_encryption_type)
    assert_equal(encr_pw, vvl.authentication_key_password)
    vvl.authentication_key_set(vvl.default_authentication_key_encryption_type,
                               vvl.default_authentication_key_password)
    assert_equal(vvl.default_authentication_key_encryption_type,
                 vvl.authentication_key_encryption_type)
    assert_equal(vvl.default_authentication_key_password,
                 vvl.authentication_key_password)
  end

  def test_message_digest_key
    dvl = create_routerospfarea_default_virtual_link
    assert_equal(dvl.default_message_digest_algorithm_type,
                 dvl.message_digest_algorithm_type)
    assert_equal(dvl.default_message_digest_encryption_type,
                 dvl.message_digest_encryption_type)
    assert_equal(dvl.default_message_digest_key_id,
                 dvl.message_digest_key_id)
    assert_equal(dvl.default_message_digest_password,
                 dvl.message_digest_password)
    key = 45
    alg = :md5
    encr = :"3des"
    encr_pw = '1347c56888deb142'
    dvl.message_digest_key_set(key, alg, encr, encr_pw)
    assert_equal(key, dvl.message_digest_key_id)
    assert_equal(alg, dvl.message_digest_algorithm_type)
    assert_equal(encr, dvl.message_digest_encryption_type)
    assert_equal(encr_pw, dvl.message_digest_password)
    key = 200
    encr = :cisco_type_7
    encr_pw = '046E1803362E595C260E0B240619050A2D'
    dvl.message_digest_key_set(key, alg, encr, encr_pw)
    assert_equal(key, dvl.message_digest_key_id)
    assert_equal(alg, dvl.message_digest_algorithm_type)
    assert_equal(encr, dvl.message_digest_encryption_type)
    assert_equal(encr_pw, dvl.message_digest_password)
    dvl.message_digest_key_set(dvl.message_digest_key_id,
                               dvl.default_message_digest_algorithm_type,
                               dvl.default_message_digest_encryption_type,
                               dvl.default_message_digest_password)
    assert_equal(dvl.default_message_digest_algorithm_type,
                 dvl.message_digest_algorithm_type)
    assert_equal(dvl.default_message_digest_encryption_type,
                 dvl.message_digest_encryption_type)
    assert_equal(dvl.default_message_digest_key_id,
                 dvl.message_digest_key_id)
    assert_equal(dvl.default_message_digest_password,
                 dvl.message_digest_password)
    vvl = create_routerospfarea_vrf_virtual_link
    assert_equal(vvl.default_message_digest_algorithm_type,
                 vvl.message_digest_algorithm_type)
    assert_equal(vvl.default_message_digest_encryption_type,
                 vvl.message_digest_encryption_type)
    assert_equal(vvl.default_message_digest_key_id,
                 vvl.message_digest_key_id)
    assert_equal(vvl.default_message_digest_password,
                 vvl.message_digest_password)
    key = 82
    encr = :"3des"
    encr_pw = '762bc328e3bdf235'
    vvl.message_digest_key_set(key, alg, encr, encr_pw)
    assert_equal(key, vvl.message_digest_key_id)
    assert_equal(alg, vvl.message_digest_algorithm_type)
    assert_equal(encr, vvl.message_digest_encryption_type)
    assert_equal(encr_pw, vvl.message_digest_password)
    key = 5
    encr = :cisco_type_7
    encr_pw = '12345678901234567890'
    vvl.message_digest_key_set(key, alg, encr, encr_pw)
    assert_equal(key, vvl.message_digest_key_id)
    assert_equal(alg, vvl.message_digest_algorithm_type)
    assert_equal(encr, vvl.message_digest_encryption_type)
    assert_equal(encr_pw, vvl.message_digest_password)
    vvl.message_digest_key_set(key, vvl.default_message_digest_algorithm_type,
                               vvl.default_message_digest_encryption_type,
                               vvl.default_message_digest_password)
    assert_equal(vvl.default_message_digest_algorithm_type,
                 vvl.message_digest_algorithm_type)
    assert_equal(vvl.default_message_digest_encryption_type,
                 vvl.message_digest_encryption_type)
    assert_equal(vvl.default_message_digest_key_id,
                 vvl.message_digest_key_id)
    assert_equal(vvl.default_message_digest_password,
                 vvl.message_digest_password)
  end
end
