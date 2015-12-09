#
# Cisco Logger Library.
#
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

require 'logger'

# Module for logging in CiscoNxapi and CiscoNodeUtils. Will automatically
# tie into Puppet or Chef logging modules if available.
module CiscoLogger
  module_function

  # Figure out what provider logging utility we
  # should use: Puppet or Chef.
  # If not found use the Ruby Logger/STDOUT/INFO.
  if defined? (Puppet::Util::Logging)
    @@logger = Puppet # rubocop:disable Style/ClassVars
    def error(string)
      @@logger.err(string)
    end

    def warn(string)
      @@logger.warning(string)
    end
  else
    if defined? (Chef::Log)
      @@logger = Chef::Log # rubocop:disable Style/ClassVars
    else
      @@logger = Logger.new(STDOUT) # rubocop:disable Style/ClassVars
      @@logger.level = Logger::INFO

      def debug_enable
        @@logger.level = Logger::DEBUG
      end

      def debug_disable
        @@logger.level = Logger::INFO
      end
    end

    def error(string)
      @@logger.error(string)
    end

    def warn(string)
      @@logger.warn(string)
    end
  end

  def debug(string)
    @@logger.debug(string)
  end

  def info(string)
    @@logger.info(string)
  end
end # module
