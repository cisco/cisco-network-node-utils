require_relative 'ciscotest'
require_relative '../lib/cisco_node_utils/span_session'
require_relative '../lib/cisco_node_utils/interface'
require_relative '../lib/cisco_node_utils/vlan'
require_relative '../lib/cisco_node_utils/cisco_cmn_utils'

include Cisco

# TestSpanSession - Minitest for SPAN session node utility
class TestSpanSession < CiscoTestCase
  @skip_unless_supported = 'session'
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
    SpanSession.sessions.each do | session,obj |
      obj.destroy
    end
  end

  def test_create_new_session
    span = SpanSession.new(1)

    assert_equal(span.session_id,1)
    assert_equal(span.type,'local') # default session type
    assert(span.shutdown)
    span.destroy
  end

  def test_remove_session
    span = SpanSession.new(1)
    span.destroy
    refute(span, 'Session was not cleaned up correctly...')
  end

  def test_create_session_invalid_id
    e = assert_raises(CliError) { SpanSession.new(33) }
    assert_match(/Invalid value.range/, e.message)
  end

  def test_session_type
    span = SpanSession.new(1)
    erspan_type = 'erspan-source'
    span.type = erspan_type
    assert_equal(span.type,erspan_type)
    span.destroy
  end

  def test_session_description
    span = SpanSession.new(1)
    desc = 'SPAN session 1'
    span.description = desc
    assert_equal(span.description,desc)
    span.destroy
  end

  def test_session_source_interface
    span = SpanSession.new(1)
    po_int = Interface.new('port-channel1')
    ints = {
      'Ethernet1/1' => 'rx',
      'Ethernet1/2' => 'tx',
      'port-channel1' => 'both',
      'sup-eth0' => 'rx',
    }
    span.source_interface(ints)
    ints.keys.each do |int_name|
      assert_equal(span.source_interface,int_name,
                  "source interface #{int_name} does not match")
    end
    span.destroy
    po_int.destroy
  end

  def test_session_source_vlans
    vlans = [2..5, 8, 10, 13]
    vlans = vlans.join(',') if vlans.is_a?(Array)
    vlans = Utils.normalize_range_array(vlans, :string) unless vlans == 'none'
    span = SpanSession.new(1)
    span.source_vlan(vlans: vlans, direction: 'rx')
    assert_equal(span.source_vlan[:vlans], vlans)
    span.destroy
  end

  def test_session_destination_int
    span = SpanSession.new(1)
    dest_int = 'Ethernet1/3'
    span.destination(intf_name: dest_int)
    assert_equal(span.destination, dest_int)
    span.destroy
  end
end
