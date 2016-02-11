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
require_relative '../lib/cisco_node_utils/cisco_cmn_utils'
require_relative '../lib/cisco_node_utils/interface_ospf'
require_relative '../lib/cisco_node_utils/router_ospf'

include Cisco

# TestInterfaceOspf - Minitest for InterfaceOspf node utility class.
class TestInterfaceOspf < CiscoTestCase
  def setup
    super
    config 'no feature ospf'
  end

  def teardown
    config 'no feature ospf'
    super
  end

  def interface_switchport_enable(ifname, enable)
    if enable == true
      config("interface #{ifname}", 'switchport')
    else
      config("interface #{ifname}", 'no switchport')
    end
  end

  def show_cmd(name)
    case name
    when /ort-channel/
      "show run interface #{name} | no-more"
    else
      "show run interface #{name} all | no-more"
    end
  end

  def create_routerospf(ospfname='ospfTest')
    config('feature ospf')
    RouterOspf.new(ospfname, false)
  end

  def create_interfaceospf(routerospf, ifname=interfaces[0], area='0.0.0.0')
    @default_show_command = show_cmd(ifname)
    interface_switchport_enable(ifname, false)
    InterfaceOspf.new(ifname, routerospf.name, area)
  end

  def test_get_set_area
    # setup a loopback to use
    config('interface loopback12')

    int_ospf = InterfaceOspf.new('loopback12', '12', '0.0.0.0')

    # test invalid
    assert_raises(CliError) do
      int_ospf.area = 'Blue'
    end

    # test get/set ip address form
    int_ospf.area = '0.0.0.4'
    assert_equal(int_ospf.area, '0.0.0.4')

    # test get/set integer form.
    # Note: the area getter will munge the value to dotted decimal.
    int_ospf.area = '3'
    assert_equal(int_ospf.area, '0.0.0.3')

    # cleanup
    config('no interface loopback12')
  end

  def test_interfaceospf_collection_empty
    config('no feature ospf', 'feature ospf', 'router ospf TestOSPF')

    routers = RouterOspf.routers()
    routers.each_value do |router|
      interfaces = InterfaceOspf.interfaces(router.name)
      assert_empty(interfaces,
                   'InterfaceOspf collection is not empty')
    end
  end

  def test_interfaceospf_collection_not_empty
    ifname1 = interfaces[1].downcase
    ifname2 = interfaces[2].downcase
    ospf1 = 'TestOSPF'
    ospf2 = 'bxb300'
    # pre-configure
    interface_switchport_enable(ifname1, false)
    interface_switchport_enable(ifname2, false)
    config('no feature ospf',
           'feature ospf',
           "router ospf #{ospf1}",
           "interface #{ifname1}",
           "ip router ospf #{ospf1} area 0.0.0.0",
           "router ospf #{ospf2}",
           "interface #{ifname2}",
           "ip router ospf #{ospf2} area 10.6.6.1",
          )

    routers = RouterOspf.routers()
    # validate the collection
    routers.each_value do |router|
      interfaces = InterfaceOspf.interfaces(router.name)
      refute_empty(interfaces,
                   'InterfaceOspf collection is empty')
      assert_equal(1, interfaces.size,
                   "InterfaceOspf collection (#{interfaces}) size is not 1")
      interfaces.each do |ifname, interface|
        pattern = (/\s+ip router ospf #{router.name} area #{interface.area}/)
        assert_show_match(command: show_cmd(ifname),
                          pattern: pattern)
        # using default check, since not configured anything
        assert_equal(node.config_get_default('interface_ospf', 'cost'),
                     interface.cost,
                     'Error: get cost failed')
        assert_equal(node.config_get_default('interface_ospf',
                                             'hello_interval'),
                     interface.hello_interval,
                     'Error: get hello interval failed')
        assert_equal(node.config_get_default('interface_ospf',
                                             'dead_interval'),
                     interface.dead_interval,
                     'Error: get dead interval failed')
        assert_equal(node.config_get_default('interface_ospf',
                                             'passive_interface'),
                     interface.passive_interface,
                     'Error: passive interface get failed')
        assert_equal(node.config_get_default('interface_ospf',
                                             'message_digest'),
                     interface.message_digest,
                     'Error: message digest get failed')
        assert_equal(node.config_get_default('interface_ospf',
                                             'message_digest_key_id'),
                     interface.message_digest_key_id,
                     'Error: message digest key get failed')
      end
    end
  end

  def test_interfaceospf_create_routerospf_nil
    assert_raises(TypeError) do
      InterfaceOspf.new(interfaces[0], nil, '0.0.0.0')
    end
  end

  def test_interfaceospf_create_interface_name_zero_length
    name = 'ospfTest'
    ospf = RouterOspf.new(name)
    assert_raises(ArgumentError) do
      InterfaceOspf.new('', ospf.name, '0.0.0.0')
    end
  end

  def test_interfaceospf_create_interface_area_zero_length
    name = 'ospfTest'
    ospf = RouterOspf.new(name)
    assert_raises(ArgumentError) do
      InterfaceOspf.new(interfaces[0], ospf.name, '')
    end
  end

  def test_routerospf_create_valid
    ospf = create_routerospf
    ifname = interfaces[1]
    area = '0.0.0.0'
    interface_switchport_enable(ifname, false)
    interface = InterfaceOspf.new(ifname, ospf.name, area)
    pattern = (/\s+ip router ospf #{ospf.name} area #{area}/)
    assert_show_match(command: show_cmd(ifname),
                      pattern: pattern)
    assert_equal(ifname.downcase, interface.interface.name,
                 'Error: interface name get value mismatch ')
    assert_equal(area, interface.area,
                 'Error: area get value mismatch ')
  end

  def test_interfaceospf_destroy
    ifname = interfaces[1]
    area = '0.0.0.0'
    ospf = create_routerospf
    interface = create_interfaceospf(ospf, ifname, area)
    interface.destroy
    refute_show_match(pattern: /\s+ip router ospf #{ospf.name} area #{area}/,
                      msg:     "'ip router ospf #{ospf.name} area #{area}' " \
                                 'not destroyed')
    # check all the attributes are set to default.
    refute_show_match(pattern: /^\s+ip ospf cost \S+/,
                      msg:     "'cost' not removed")

    refute_show_match(pattern: /^\s+ip ospf hello-interval \S+/,
                      msg:     "'hello-interval' not removed")

    # with default CLI still shows the value
    refute_show_match(pattern: /^\s+ip ospf dead-interval \S+/,
                      msg:     "'dead-interval' not removed")

    refute_show_match(pattern: /^\s+ip ospf passive-interface/,
                      msg:     "'passive interface' not removed")
  end

  def test_routerospf_get_parent
    ospf = create_routerospf
    interface = create_interfaceospf(ospf)
    assert_equal(ospf.name, interface.ospf_name)
  end

  def test_interfaceospf_cost_invalid_range
    ospf = create_routerospf
    interface = create_interfaceospf(ospf)
    # upper range
    assert_raises(CliError) do
      interface.cost = 65_536
    end
    # lower range just removes the config.
    # assert_raises(RuntimeError) do
    #  interface.cost = 0
    # end
  end

  def test_interfaceospf_cost
    ospf = create_routerospf
    interface = create_interfaceospf(ospf)
    cost = 1000
    # set with value
    interface.cost = cost
    assert_show_match(pattern: /\s+ip ospf cost #{cost}/,
                      msg:     'Error: cost missing in CLI')
    assert_equal(cost, interface.cost,
                 'Error: cost get value mismatch')
    # set default
    interface.cost = interface.default_cost
    refute_show_match(pattern: /\s+ip ospf cost(.*)/,
                      msg:     'Error: default cost set failed')
  end

  def test_interfaceospf_hello_interval_invalid_range
    ospf = create_routerospf
    interface = create_interfaceospf(ospf)
    # upper range
    assert_raises(CliError) do
      interface.hello_interval = 65_536
    end
    # lower range
    assert_raises(CliError) do
      interface.hello_interval = 0
    end
  end

  def test_interfaceospf_hello_interval
    ospf = create_routerospf
    interface = create_interfaceospf(ospf)
    interval = 90
    # set with value
    interface.hello_interval = interval
    assert_show_match(pattern: /\s+ip ospf hello-interval #{interval}/,
                      msg:     'Error: hello-interval missing in CLI')
    assert_equal(interval, interface.hello_interval,
                 'Error: hello-interval get value mismatch')

    # set default, when we set default CLI does not show it
    interface.hello_interval = interface.default_hello_interval
    refute_show_match(pattern: /\s+ip ospf hello-interval(.*)/,
                      msg:     'Error: default hello-interval set failed')
  end

  def test_interfaceospf_dead_interval_invalid_range
    ospf = create_routerospf
    interface = create_interfaceospf(ospf)

    ref = cmd_ref.lookup('interface_ospf', 'dead_interval')
    assert(ref, 'Error, reference not found for dead_interval')

    # upper range
    assert_raises(CliError) do
      interface.dead_interval = 262_141
    end
    # lower range
    assert_raises(CliError) do
      interface.dead_interval = 0
    end
  end

  def test_interfaceospf_dead_interval
    ospf = create_routerospf
    interface = create_interfaceospf(ospf)
    interval = 150
    # set with value
    interface.dead_interval = interval
    assert_show_match(pattern: /\s+ip ospf dead-interval #{interval}/,
                      msg:     'Error: dead-interval missing in CLI')
    assert_equal(interval, interface.dead_interval,
                 'Error: dead-interval get value mismatch')
    # set default, the CLI shows with default value
    interface.dead_interval = interface.default_dead_interval
    assert_show_match(
      pattern: /^\s+ip ospf dead-interval #{interface.default_dead_interval}/,
      msg:     'Error: default dead-interval set failed')
  end

  def test_interfaceospf_passive_interface
    ospf = create_routerospf
    interface = create_interfaceospf(ospf)

    # set with value
    interface.passive_interface = true
    assert_show_match(pattern: /\s+ip ospf passive-interface/,
                      msg:     'passive interface enable missing in CLI')
    assert(interface.passive_interface,
           'Error: passive interface get value mismatch')

    # get default and set
    interface.passive_interface = interface.default_passive_interface
    assert_show_match(pattern: /\s+no ip ospf passive-interface/,
                      msg:     'default passive interface set failed')
  end

  def test_interfaceospf_create_valid_multiple
    # ospf and interfaces[0]
    ospf = create_routerospf
    interface = create_interfaceospf(ospf)
    assert_show_match(
      pattern: /\s+ip router ospf #{ospf.name} area #{interface.area}/,
      msg:     "'ip router ospf #{ospf.name} default area' not configured")

    # ospf and interfaces_id[2]
    ifname = interfaces[2]
    area = '1.1.1.1'
    create_interfaceospf(ospf, ifname, area)
    assert_show_match(
      pattern: /\s+ip router ospf #{ospf.name} area #{area}/,
      msg:     "'ip router ospf #{ospf.name} area #{area}' is not configured")
  end

  def test_interfaceospf_create_multiple_delete_one
    # ospf and interfaces[0]
    ospf = create_routerospf
    interface = create_interfaceospf(ospf)

    # ospf and interfaces_id[2]
    ifname = interfaces[2]
    area = '1.1.1.1'
    interface1 = create_interfaceospf(ospf, ifname, area)
    assert_equal(ifname.downcase, interface1.interface.name,
                 "Error: 'ip router ospf #{ospf.name} area #{area}' " \
                 'not configured')

    # delete ospf instance from interfaces_id[2]
    interface1.destroy
    refute_show_match(
      command: show_cmd(ifname),
      pattern: /\s+ip router ospf #{ospf.name} area #{area}/,
      msg:     "'ip router ospf #{ospf.name} area #{area}' not deleted")

    # check other interface association still exist.
    assert_show_match(
      command: show_cmd(interface.interface.name),
      pattern: /\s+ip router ospf #{ospf.name} area #{interface.area}/,
      msg:     "'ip router ospf #{ospf.name} default area' not configured")
  end

  def configure_from_hash(hash)
    hash.each do |k, v|
      # puts "TEST: pre-config hash key : #{k}"
      config("router ospf #{k}")
      v.each do |k1, v1|
        # puts "TEST: pre-config k1: v1 '#{k1} : #{v1}'"
        cfg = ["interface #{k1}"]
        if !(/^ethernet\d.\d/).match(k1.to_s).nil? ||
           !(/^port-channel\d/).match(k1.to_s).nil?
          cfg << 'no switchport'
          # puts "switchport disable: #{k1}"
        end
        # puts "k1: #{k1}, k:  #{k},   area   #{v1[:area]}"
        cfg << "ip router ospf #{k} area #{v1[:area]}"
        cfg << "ip ospf cost #{v1[:cost]}" unless v1[:cost].nil?
        cfg << "ip ospf hello-interval #{v1[:hello]}" unless v1[:hello].nil?
        cfg << "ip ospf dead-interval #{v1[:dead]}" unless v1[:dead].nil?
        cfg << 'ip ospf passive-interface' if !v1[:pass].nil? &&
                                              v1[:pass] == true
        config(*cfg)
      end
    end
  end

  def multiple_interface_config_hash
    # rubocop:disable Style/AlignHash
    hash = {
      'ospfTest' => {
        interfaces[0].downcase => {
          area: '0.0.0.0', cost: 10, hello: 30, dead: 120, pass: true },
        interfaces[1].downcase => {
          area: '1.1.1.38', dead: 40, pass: false },
        'vlan101'              => {
          area: '2.2.2.101', cost: 5, hello: 20, dead: 80, pass: true },
      },
      'TestOspfInt' => {
        interfaces[2].downcase => {
          area: '0.0.0.19' },
        'vlan290'              => {
          area: '2.2.2.29', cost: 200, hello: 30, dead: 120, pass: true },
        'port-channel100'      => {
          area: '3.2.2.29', cost: 25, hello: 50, dead: 200, pass: false },
      },
    }
    # rubocop:enable Style/AlignHash
    # Set defaults
    hash.each_key do |name|
      hash[name].each_value do |hv|
        hv[:cost] ||= node.config_get_default('interface_ospf', 'cost')
        hv[:hello] ||= node.config_get_default('interface_ospf',
                                               'hello_interval')
        hv[:dead] ||= node.config_get_default('interface_ospf',
                                              'dead_interval')
        hv[:pass] ||= node.config_get_default('interface_ospf',
                                              'passive_interface')
      end
    end
  end

  def test_interfaceospf_collection_multiple_interface
    s = config('int port-channel 42', 'descr foo')
    known_failure = s[/ERROR:.*port channel not present/]
    refute(known_failure, 'ERROR: port channel not present')

    ospf_h = multiple_interface_config_hash

    # enable feature ospf
    config('no feature ospf',
           'feature ospf',
           'feature interface-vlan',
           'default interface interfaces[0]',
           'default interface interfaces[1]',
           'default interface interfaces[2]',
          )

    # pre-configure
    configure_from_hash(ospf_h)

    routers = RouterOspf.routers()
    # validate the collection
    routers.each do |name, router|
      interfaces = InterfaceOspf.interfaces(router.name)
      refute_empty(interfaces, 'InterfaceOspf collection is empty')
      assert_includes(ospf_h, name)
      ospfh = ospf_h.fetch(name)
      assert_equal(ospfh.size, interfaces.size,
                   "InterfaceOspf #{name} collection size mismatch")
      interfaces.each do |ifname, interface|
        assert_includes(ospfh, ifname)
        hv = ospfh.fetch(ifname)
        assert_show_match(
          command: show_cmd(ifname),
          pattern: /\s+ip router ospf #{name} area #{hv[:area]}/,
          msg:     "Error: ip router ospf #{name} area #{hv[:area]} "\
                   "not found under #{ifname}")

        assert_equal(hv[:cost], interface.cost, 'Error: get cost failed')
        assert_equal(hv[:hello], interface.hello_interval,
                     'Error: get hello interval failed')
        assert_equal(hv[:dead], interface.dead_interval,
                     'Error: get dead interval failed')
        assert_equal(hv[:pass], interface.passive_interface,
                     'Error: passive interface get failed')
      end
    end # interfaces hash
    # clean up

    # disable feature interface-vlan
    config('no feature interface-vlan')
    # clean up port channel
    ospf_h.each_value do |v|
      v.each_key do |k1|
        config("no interface #{k1}") if (/^port-channel\d/).match(k1)
      end # v each
    end # ospf_h each
  end

  def test_interfaceospf_message_digest
    ospf = create_routerospf
    interface = create_interfaceospf(ospf)

    # set with value
    interface.message_digest = true
    pattern = (/^\s+ip ospf authentication message-digest$/)
    assert_show_match(pattern: pattern,
                      msg:     'Error: message digest enable missing in CLI')
    assert(interface.message_digest,
           'Error: message digest is false but should be true')

    # get default and set
    interface.message_digest = interface.default_message_digest
    refute_show_match(pattern: pattern,
                      msg:     'Error: default message digest set failed')
    refute(interface.message_digest,
           'Error: message digest is true but should be false (default)')
  end

  def test_interfaceospf_message_digest_key
    ospf = create_routerospf
    interface = create_interfaceospf(ospf)
    # auth params
    keyid = 1
    algo = :md5
    encr = :cleartext

    # set with value
    interface.message_digest_key_set(keyid, algo, encr, 'test123')
    # need to revist TODO
    line = assert_show_match(
      pattern: /^\s+ip ospf message-digest-key #{keyid} md5 \S \S+$/,
      msg:     'message digest authentication with cleartext missing in CLI')
    # TODO: assert(interface.message_digest,
    #             "Error: message digest get value mismatch")
    # check key id exist
    assert_equal(keyid, interface.message_digest_key_id,
                 "Error: message digest key #{keyid} not present")
    # save encrypted password
    md = /3 (\S+)$/.match(line.to_s)
    encrypted_password = md.to_s.split(' ').last
    assert_equal(encrypted_password, interface.message_digest_password)

    # Check other attributes:
    assert_equal(algo, interface.message_digest_algorithm_type)
    assert_equal(:"3des", interface.message_digest_encryption_type)

    # unconfigure auth
    keyid = interface.default_message_digest_key_id
    encr = :cleartext
    interface.message_digest_key_set(keyid, algo, encr, 'test123')
    refute_show_match(pattern: /^\s+ip ospf message-digest-key #{keyid} .+/,
                      msg:     'message digest auth still present in CLI')
    assert_equal(interface.message_digest_key_id,
                 interface.default_message_digest_key_id)
    assert_equal(interface.message_digest_algorithm_type,
                 interface.default_message_digest_algorithm_type)
    assert_equal(interface.message_digest_encryption_type,
                 interface.default_message_digest_encryption_type)

    # update enc with 3DES
    keyid = 1
    encr = :"3des"
    interface.message_digest_key_set(keyid, algo, encr, encrypted_password)
    assert_show_match(
      pattern: /^\s+ip ospf message-digest-key #{keyid} md5 3 \S+$/,
      msg:     'message digest authentication with 3DES missing in CLI')
    assert_equal(keyid, interface.message_digest_key_id)
    assert_equal(algo, interface.message_digest_algorithm_type)
    assert_equal(encr, interface.message_digest_encryption_type)
    assert_equal(encrypted_password, interface.message_digest_password)

    # update enc with cisco type 7
    keyid = 1
    encr = :cisco_type_7
    interface.message_digest_key_set(keyid, algo, encr, encrypted_password)
    assert_show_match(
      pattern: /^\s+ip ospf message-digest-key #{keyid} md5 7 \S+$/,
      msg:     'message digest authentication with cisco type 7 missing in CLI')
    assert_equal(keyid, interface.message_digest_key_id)
    assert_equal(algo, interface.message_digest_algorithm_type)
    assert_equal(encr, interface.message_digest_encryption_type)
  end

  def test_interfaceospf_message_digest_key_invalid_password
    ospf = create_routerospf
    interface = create_interfaceospf(ospf)

    # blank password
    keyid = 1
    algo = :md5
    encr = :cleartext
    password = ''
    assert_raises(ArgumentError) do
      interface.message_digest_key_set(keyid, algo, encr, password)
    end

    # mismatch password and encryption
    encr = :"3des"
    password = 'test123'
    assert_raises(CliError) do
      interface.message_digest_key_set(keyid, algo, encr, password)
    end
  end

  def test_interfaceospf_nonexistent
    # If the interface does exist but the OSPF instance does not, this is OK
    config('interface loopback122')
    interface = InterfaceOspf.new('loopback122', 'nonexistentOspf', '0')

    # Note: the area getter will munge the value to dotted decimal.
    assert_equal(interface.area, '0.0.0.0')
    assert_equal(interface.hello_interval, interface.default_hello_interval)

    interface.destroy

    # If the interface doesn't exist, InterfaceOspf should raise an error
    config('no interface loopback122')
    assert_raises(RuntimeError) do
      interface = InterfaceOspf.new('loopback122', 'nonexistentOspf', '0')
    end
  end
end
