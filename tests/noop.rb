require_relative 'ciscotest'
# NOOP class for CI development use only
class Noop < CiscoTestCase
  def test_noop
    assert(true)
  end
end
