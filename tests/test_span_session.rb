require_relative 'ciscotest'
require_relative '../lib/cisco_node_utils/span_session'
require_relative '../lib/cisco_node_utils/interface'
require_relative '../lib/cisco_node_utils/vlan'
require_relative '../lib/cisco_node_utils/cisco_cmn_utils'

include Cisco

# TestSpanSession - Minitest for SPAN session node utility
class TestSpanSession < CiscoTestCase
  @skip_unless_supported = 'span_session'
  @@cleaned = false # rubocop:disable Style/ClassVars

  def setup
    super
    cleanup unless @@cleaned
    @@cleaned = true # rubocop:disable Style/ClassVars
  end

  def teardown
    cleanup
  end

  def cleanup
    SpanSession.sessions.each do |_session, obj|
      obj.destroy
    end
  end

  def test_create_new_session
    span = SpanSession.new(1)

    assert_equal(span.session_id, 1)
    assert_equal(span.type, 'local') # default session type
    assert(span.shutdown)
  end

  def test_remove_session
    span = SpanSession.new(1)
    span.destroy
    refute(span.session_id, 'Session was not cleaned up correctly...')
  end

  def test_create_session_invalid_id
    e = assert_raises(CliError) { SpanSession.new(33) }
    assert_match(/Invalid value.range/, e.message)
  end

  def test_session_type
    span = SpanSession.new(2)
    erspan_type = 'erspan-source'
    span.type = erspan_type
    assert_equal(span.type, erspan_type)
  end

  def test_session_description
    span = SpanSession.new(3)
    desc = 'SPAN session 1'
    span.description = desc
    assert_equal(span.description, desc)
  end

  def test_session_source_interfaces
    span = SpanSession.new(4)
    po_int = Interface.new('port-channel1')
    int1 = interfaces[0]
    int2 = interfaces[1]
    int3 = interfaces[2]

    # Test default case
    assert_equal(span.default_source_interfaces, span.source_interfaces)

    # Non-default case
    intla = { int1            => 'rx',
              int2            => 'tx',
              'port-channel1' => 'both',
              'sup-eth0'      => 'rx' }

    span.source_interfaces = intla
    assert_equal(intla.to_a.sort, span.source_interfaces.sort)

    # intla and intlb are identical
    intlb = { int1            => 'rx',
              int2            => 'tx',
              'port-channel1' => 'both',
              'sup-eth0'      => 'rx' }

    span.source_interfaces = intlb
    assert_equal(intlb.to_a.sort, span.source_interfaces.sort)

    # intla/c same size but 1 element different
    intlc = { int2            => 'both',
              int1            => 'rx',
              'port-channel1' => 'both',
              'sup-eth0'      => 'rx' }

    span.source_interfaces = intlc
    assert_equal(intlc.to_a.sort, span.source_interfaces.sort)

    # intla/d different sizes and diff/same elements
    intld = { int2            => 'tx',
              int1            => 'both',
              'port-channel1' => 'both' }

    span.source_interfaces = intld
    assert_equal(intld.to_a.sort, span.source_interfaces.sort)

    # Empty list
    intle = {}

    span.source_interfaces = intle
    assert_equal(intle.to_a.sort, span.source_interfaces.sort)

    # intlf is larger then intla
    intlf = { int3            => 'both',
              int1            => 'rx',
              int2            => 'tx',
              'port-channel1' => 'both',
              'sup-eth0'      => 'rx' }

    span.source_interfaces = intlf
    assert_equal(intlf.to_a.sort, span.source_interfaces.sort)

    po_int.destroy
  end

  def test_session_source_vlans
    span = SpanSession.new(5)

    # Default case
    assert_equal(span.source_vlans, span.default_source_vlans)

    # Non-default case
    vlans = %w(1 2-5 6)
    span.source_vlans = { vlans: vlans, direction: 'rx' }
    assert_equal(%w(1-6), span.source_vlans[0])
    assert_equal('rx', span.source_vlans[1])

    vlans = %w(1 3-4 6)
    span.source_vlans = { vlans: vlans, direction: 'rx' }
    assert_equal(%w(1 3-4 6), span.source_vlans[0])
    assert_equal('rx', span.source_vlans[1])

    # Set back to default
    span.source_vlans = { vlans: [], direction: '' }
    assert_equal(span.source_vlans, span.default_source_vlans)
  end

  def test_session_destination_int
    span = SpanSession.new(6)
    dest_int = interfaces[2]
    span.destination = dest_int
    assert_equal(span.destination, dest_int)
  end
end
