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
  @skip_unless_supported = 'interface_ospf'

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

  # Test InterfaceOspf.interfaces class method api
  def test_interfaces_api
    intf = interfaces[0]
    intf2 = interfaces[1]

    # Verify single_intf usage when no ospf config on intf
    none = InterfaceOspf.interfaces(nil, intf)
    assert_equal(none.keys.length, 0,
                 'Invalid number of keys returned, should be 0')

    # Verify single_intf usage when ospf config present on intf
    InterfaceOspf.new(intf, 'ospf_test', '0')
    one = InterfaceOspf.interfaces(nil, intf)
    assert_equal(one.keys.length, 1,
                 'Invalid number of keys returned, should be 1')
    assert_equal(one[intf].get_args[:show_name], intf,
                 ':show_name should be intf name when single_intf param specified')

    # Verify 'all' interfaces returned
    Interface.new(intf2)
    InterfaceOspf.new(intf2, 'ospf_test', '0')
    all = InterfaceOspf.interfaces
    assert_operator(all.keys.length, :>, 1,
                    'Invalid number of keys returned, should exceed 1')
    assert_empty(all[intf2].get_args[:show_name],
                 ':show_name should be empty string when single_intf param is nil')

    # Test with ospf_name parameter specified
    all = InterfaceOspf.interfaces('ospf_test')
    assert_operator(all.keys.length, :>, 1,
                    'Invalid number of keys returned, should exceed 1')
    assert_empty(all[intf2].get_args[:show_name],
                 ':show_name should be empty string when single_intf param is nil')

    one = InterfaceOspf.interfaces('ospf_test', intf2)
    assert_equal(one.keys.length, 1,
                 'Invalid number of keys returned, should be 1')
    assert_equal(one[intf2].get_args[:show_name], intf2,
                 ':show_name should be intf2 name when single_intf param specified')

    # Test non-existent loopback raises fail
    if Interface.interfaces(nil, 'loopback543').any?
      Interface.new('loopback543', false).destroy
    end
    assert_raises(RuntimeError) do
      InterfaceOspf.new('loopback543', 'ospf_test', '0', false)
    end
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

  def test_collection_empty
    config('no feature ospf', 'feature ospf', 'router ospf TestOSPF')

    routers = RouterOspf.routers()
    routers.each_value do |router|
      interfaces = InterfaceOspf.interfaces(router.name)
      assert_empty(interfaces,
                   'InterfaceOspf collection is not empty')
    end
  end

  def test_collection_not_empty
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
                                             'bfd'),
                     interface.bfd,
                     'Error: bfd get failed')
        assert_equal(node.config_get_default('interface_ospf',
                                             'mtu_ignore'),
                     interface.mtu_ignore,
                     'Error: mtu_ignore get failed')
        assert_equal(node.config_get_default('interface_ospf',
                                             'priority'),
                     interface.priority,
                     'Error: priority get failed')
        assert_equal(node.config_get_default('interface_ospf',
                                             'network_type_default'),
                     interface.network_type,
                     'Error: network type get failed')
        assert_equal(node.config_get_default('interface_ospf',
                                             'shutdown'),
                     interface.shutdown,
                     'Error: shutdown get failed')
        assert_equal(node.config_get_default('interface_ospf',
                                             'transmit_delay'),
                     interface.transmit_delay,
                     'Error: transmit_delay get failed')
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

  def test_routerospf_nil
    assert_raises(TypeError) do
      InterfaceOspf.new(interfaces[0], nil, '0.0.0.0')
    end
  end

  def test_name_zero_length
    name = 'ospfTest'
    ospf = RouterOspf.new(name)
    assert_raises(ArgumentError) do
      InterfaceOspf.new('', ospf.name, '0.0.0.0')
    end
  end

  def test_area_zero_length
    name = 'ospfTest'
    ospf = RouterOspf.new(name)
    assert_raises(ArgumentError) do
      InterfaceOspf.new(interfaces[0], ospf.name, '')
    end
  end

  def test_routerospf
    ospf = create_routerospf
    ifname = interfaces[1]
    area = '0.0.0.0'
    interface_switchport_enable(ifname, false)
    interface = InterfaceOspf.new(ifname, ospf.name, area)
    pattern = (/\s+ip router ospf #{ospf.name} area #{area}/)
    assert_show_match(command: show_cmd(ifname),
                      pattern: pattern)
    assert_equal(ifname.downcase, interface.intf_name,
                 'Error: interface name get value mismatch ')
    assert_equal(area, interface.area,
                 'Error: area get value mismatch ')
  end

  def test_destroy
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

    refute_show_match(pattern: /^\s+ip ospf bfd \S+/,
                      msg:     "'bfd' not removed")

    refute_show_match(pattern: /^\s+ip ospf mtu-ignore \S+/,
                      msg:     "'mtu_ignore' not removed")

    refute_show_match(pattern: /^\s+ip ospf shutdown \S+/,
                      msg:     "'shutdown' not removed")

    refute_show_match(pattern: /^\s+ip ospf transmit-delay \S+/,
                      msg:     "'transmit_delay' not removed")

    refute_show_match(pattern: /^\s+ip ospf priority \S+/,
                      msg:     "'priority' not removed")

    refute_show_match(pattern: /^\s+ip ospf network point-to-point/,
                      msg:     "'network_type' not removed")

    refute_show_match(pattern: /^\s+ip ospf passive-interface/,
                      msg:     "'passive interface' not removed")
  end

  def test_get_parent
    ospf = create_routerospf
    interface = create_interfaceospf(ospf)
    assert_equal(ospf.name, interface.ospf_name)
  end

  def test_cost_inv
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

  def test_cost
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

  def test_hello_inv
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

  def test_hello
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

  def test_dead_inv
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

  def test_dead
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

  def test_bfd
    ospf = create_routerospf
    interface = create_interfaceospf(ospf)
    assert_equal(interface.default_bfd, interface.bfd)
    interface.bfd = true
    assert_equal(true, interface.bfd)
    interface.bfd = false
    assert_equal(false, interface.bfd)
    interface.bfd = interface.default_bfd
    assert_equal(interface.default_bfd, interface.bfd)
  end

  def test_mtu_ignore
    ospf = create_routerospf
    interface = create_interfaceospf(ospf)
    assert_equal(interface.default_mtu_ignore, interface.mtu_ignore)
    interface.mtu_ignore = true
    assert_equal(true, interface.mtu_ignore)
    interface.mtu_ignore = interface.default_mtu_ignore
    assert_equal(interface.default_mtu_ignore, interface.mtu_ignore)
  end

  def test_network_type
    ospf = create_routerospf
    interface = create_interfaceospf(ospf)

    assert_equal(interface.default_network_type, interface.network_type)
    interface.network_type = 'p2p'
    assert_equal('p2p', interface.network_type)
    interface.network_type = interface.default_network_type
    assert_equal(interface.default_network_type, interface.network_type)

    # setup a loopback to use
    config('interface loopback12')
    interface = InterfaceOspf.new('loopback12', '12', '0.0.0.0')
    assert_equal(interface.default_network_type, interface.network_type)
    interface.network_type = 'p2p'
    assert_equal('p2p', interface.network_type)
    interface.network_type = interface.default_network_type
    assert_equal(interface.default_network_type, interface.network_type)
    # cleanup
    config('no interface loopback12')
  end

  def test_passive
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

  def test_priority
    ospf = create_routerospf
    interface = create_interfaceospf(ospf)
    assert_equal(interface.default_priority, interface.priority)
    interface.priority = 100
    assert_equal(100, interface.priority)
    interface.priority = interface.default_priority
    assert_equal(interface.default_priority, interface.priority)
  end

  def test_shutdown
    ospf = create_routerospf
    interface = create_interfaceospf(ospf)
    assert_equal(interface.default_shutdown, interface.shutdown)
    interface.shutdown = true
    assert_equal(true, interface.shutdown)
    interface.shutdown = interface.default_shutdown
    assert_equal(interface.default_shutdown, interface.shutdown)
  end

  def test_transmit_delay
    ospf = create_routerospf
    interface = create_interfaceospf(ospf)
    assert_equal(interface.default_transmit_delay, interface.transmit_delay)
    interface.transmit_delay = 400
    assert_equal(400, interface.transmit_delay)
    interface.transmit_delay = interface.default_transmit_delay
    assert_equal(interface.default_transmit_delay, interface.transmit_delay)
  end

  def test_mult
    # ospf and interfaces[0]
    ospf = create_routerospf
    interface = create_interfaceospf(ospf)
    assert_show_match(
      pattern: /\s+ip router ospf #{ospf.name} area #{interface.area}/,
      msg:     "'ip router ospf #{ospf.name} default area' not configured")

    ifname = interfaces[2]
    area = '1.1.1.1'
    create_interfaceospf(ospf, ifname, area)
    assert_show_match(
      pattern: /\s+ip router ospf #{ospf.name} area #{area}/,
      msg:     "'ip router ospf #{ospf.name} area #{area}' is not configured")
  end

  def test_mult_delete_one
    # ospf and interfaces[0]
    ospf = create_routerospf
    interface = create_interfaceospf(ospf)

    ifname = interfaces[2]
    area = '1.1.1.1'
    interface1 = create_interfaceospf(ospf, ifname, area)
    assert_equal(ifname.downcase, interface1.intf_name,
                 "Error: 'ip router ospf #{ospf.name} area #{area}' " \
                 'not configured')

    interface1.destroy
    refute_show_match(
      command: show_cmd(ifname),
      pattern: /\s+ip router ospf #{ospf.name} area #{area}/,
      msg:     "'ip router ospf #{ospf.name} area #{area}' not deleted")

    # check other interface association still exist.
    assert_show_match(
      command: show_cmd(interface.intf_name),
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
        cfg << 'ip ospf bfd' if v1[:bfd]
        cfg << 'ip ospf bfd disable' if v1[:bfd] == false
        cfg << 'no ip ospf bfd' if v1[:bfd].nil?
        cfg << "ip ospf cost #{v1[:cost]}" unless v1[:cost] == 0
        cfg << "ip ospf hello-interval #{v1[:hello]}" unless v1[:hello].nil?
        cfg << "ip ospf dead-interval #{v1[:dead]}" unless v1[:dead].nil?
        cfg << 'ip ospf network point-to-point' if v1[:net] == 'p2p'
        cfg << 'no ip ospf network' if v1[:net] == 'broadcast'
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
          area: '0.0.0.0', bfd: true, cost: 10, hello: 30,
          dead: 120, net: 'p2p', pass: true },
        interfaces[1].downcase => {
          area: '1.1.1.38', bfd: false, dead: 40, net: 'p2p', pass: false },
        'vlan101'              => {
          area: '2.2.2.101', bfd: true, cost: 5, hello: 20, dead: 80,
          net: 'p2p', pass: true },
      },
      'TestOspfInt' => {
        interfaces[2].downcase => {
          area: '0.0.0.19' },
        'vlan290'              => {
          area: '2.2.2.29', bfd: true, cost: 200, hello: 30,
          dead: 120, net: 'broadcast', pass: true },
        'port-channel100'      => {
          area: '3.2.2.29', bfd: false, cost: 25, hello: 50, dead: 200,
          net: 'p2p', pass: false },
      },
    }
    # rubocop:enable Style/AlignHash
    # Set defaults
    hash.each_key do |name|
      hash[name].each_value do |hv|
        hv[:bfd] ||= node.config_get_default('interface_ospf', 'bfd')
        hv[:cost] ||= node.config_get_default('interface_ospf', 'cost')
        hv[:hello] ||= node.config_get_default('interface_ospf',
                                               'hello_interval')
        hv[:dead] ||= node.config_get_default('interface_ospf',
                                              'dead_interval')
        hv[:net] ||= node.config_get_default('interface_ospf',
                                             'network_type_default')
        hv[:pass] ||= node.config_get_default('interface_ospf',
                                              'passive_interface')
      end
    end
  end

  def test_collect_mult_intf
    s = config('int port-channel 42', 'descr foo')
    known_failure = s[/ERROR:.*port channel not present/]
    refute(known_failure, 'ERROR: port channel not present')

    ospf_h = multiple_interface_config_hash

    # enable feature ospf
    config('no feature ospf',
           'feature ospf',
           'feature bfd',
           'feature interface-vlan',
           "default interface #{interfaces[0]}",
           "default interface #{interfaces[1]}",
           "default interface #{interfaces[2]}",
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

        if hv[:bfd].nil?
          assert_nil(interface.bfd, 'Error: get bfd is not nil')
        else
          assert_equal(hv[:bfd], interface.bfd, 'Error: get bfd failed')
        end
        assert_equal(hv[:cost], interface.cost, 'Error: get cost failed')
        assert_equal(hv[:hello], interface.hello_interval,
                     'Error: get hello interval failed')
        assert_equal(hv[:dead], interface.dead_interval,
                     'Error: get dead interval failed')
        assert_equal(hv[:net], interface.network_type,
                     'Error: network_type get failed')
        assert_equal(hv[:pass], interface.passive_interface,
                     'Error: passive interface get failed')
      end
    end # interfaces hash
    # clean up

    # disable feature interface-vlan
    config('no feature interface-vlan')
    config('no feature bfd')
    # clean up port channel
    ospf_h.each_value do |v|
      v.each_key do |k1|
        config("no interface #{k1}") if (/^port-channel\d/).match(k1)
      end # v each
    end # ospf_h each
  end

  def test_message_digest
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

  def test_message_digest_key
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

  def test_message_digest_key_inv
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

  def test_nonexistent
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
