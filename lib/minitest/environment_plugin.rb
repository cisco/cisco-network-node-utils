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

require_relative '../cisco_node_utils/environment'

# Add environment option to minitest
module Minitest
  def self.plugin_environment_options(opts, options)
    opts.on('-e', '--environment NAME', 'Select environment by name') do |name|
      options[:environment] = name
    end
  end

  def self.plugin_environment_init(options)
    name = options[:environment]
    Cisco::Environment.default_environment_name = name unless name.nil?
  end
end
