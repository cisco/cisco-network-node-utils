# March 2016, Glenn F. Matthews
#
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

require 'logger'
require_relative '../cisco_node_utils/logger'

# Add logging level option to minitest
module Minitest
  LEVEL_ALIASES = {
    'debug'   => Logger::DEBUG,
    'info'    => Logger::INFO,
    'warning' => Logger::WARN,
    'error'   => Logger::ERROR,
  }
  def self.plugin_log_level_options(opts, options)
    opts.on(
      '-l', '--log-level LEVEL', LEVEL_ALIASES,
      'Configure logging level for tests',
      "(#{LEVEL_ALIASES.keys.join(', ')})"
    ) do |level|
      options[:log_level] = level
    end
  end

  def self.plugin_log_level_init(options)
    Cisco::Logger.level = options[:log_level] if options[:log_level]
  end
end
