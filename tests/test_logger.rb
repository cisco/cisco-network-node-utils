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
require_relative '../lib/cisco_os_shim/core/cisco_logger'

# TestLogger - unit tests for CiscoLogger module
class TestLogger < TestCase
  def test_logger_methods
    assert(defined?(CiscoLogger.debug), 'debug method not defined')
    assert(defined?(CiscoLogger.info), 'info method not defined')
    assert(defined?(CiscoLogger.warn), 'warning method not defined')
    assert(defined?(CiscoLogger.error), 'error method not defined')
  end

  # Due to current limitation of minitest, the following test case actually
  # will never fail. But it will print out all the messages that the tested
  # functions are supposed to print. So I still keep this test here
  def test_default_logger_output
    CiscoLogger.debug_enable
    assert_output { CiscoLogger.debug('Test default debug output') }
    assert_output { CiscoLogger.info('Test default info output') }
    assert_output { CiscoLogger.warn('Test default warn output') }
    assert_output { CiscoLogger.error('Test default error output') }
    CiscoLogger.debug_disable
  end
end
