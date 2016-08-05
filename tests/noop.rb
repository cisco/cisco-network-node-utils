require_relative 'ciscotest'
# NOOP class for CI development use only
class Noop < CiscoTestCase
  @skip_unless_supported = 'noop'
end
