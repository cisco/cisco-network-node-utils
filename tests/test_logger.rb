# January 2015, Jie Yang
#
# Copyright (c) 2015 Cisco and/or its affiliates.
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

require_relative 'basetest'
require_relative '../lib/cisco_node_utils/logger'

# TestLogger - unit tests for Cisco::Logger module
class TestLogger < TestCase
  def test_logger_methods
    assert(defined?(Cisco::Logger.debug), 'debug method not defined')
    assert(defined?(Cisco::Logger.info), 'info method not defined')
    assert(defined?(Cisco::Logger.warn), 'warning method not defined')
    assert(defined?(Cisco::Logger.error), 'error method not defined')
  end

  # Due to current limitation of minitest, the following test case actually
  # will never fail. But it will print out all the messages that the tested
  # functions are supposed to print. So I still keep this test here
  def test_default_logger_output
    level = Cisco::Logger.level
    Cisco::Logger.level = Logger::DEBUG
    assert_equal(Logger::DEBUG, Cisco::Logger.level)
    assert_output { Cisco::Logger.debug('Test default debug output') }
    assert_output { Cisco::Logger.info('Test default info output') }
    assert_output { Cisco::Logger.warn('Test default warn output') }
    assert_output { Cisco::Logger.error('Test default error output') }
    Cisco::Logger.level = level
    assert_equal(level, Cisco::Logger.level)
  end
end
