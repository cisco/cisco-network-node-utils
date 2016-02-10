# September 2015, Glenn F. Matthews
#
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

require_relative 'node'

module Cisco
  # NodeUtil - generic functionality for node utility subclasses to use
  class NodeUtil
    # rubocop:disable Style/ClassVars
    # We want this to be inherited to all child classes, it's a singleton.
    @@node = nil
    # rubocop:enable Style/ClassVars

    def self.node
      # rubocop:disable Style/ClassVars
      @@node ||= Cisco::Node.instance
      # rubocop:enable Style/ClassVars
    end

    def node
      self.class.node
    end

    def self.config_get(*args)
      node.config_get(*args)
    end

    def config_get(*args)
      node.config_get(*args)
    end

    def self.config_get_default(*args)
      node.config_get_default(*args)
    end

    def config_get_default(*args)
      node.config_get_default(*args)
    end

    def self.config_set(*args)
      node.config_set(*args)
    end

    def config_set(*args)
      node.config_set(*args)
    end

    def show(*args)
      node.show(*args)
    end
  end
end
