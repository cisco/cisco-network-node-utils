# Banner provider class
#
# Rick Sherman et al., August 2018
#
# Copyright (c) 2014-2018 Cisco and/or its affiliates.
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

require_relative 'node_util'

module Cisco
  # Banner - node utility class for Banner configuration management
  class Banner < NodeUtil
    attr_reader :name

    def initialize(name)
      fail TypeError unless name.is_a?(String)
      fail ArgumentError,
           "This provider only accepts an id of 'default'" \
           unless name.eql?('default')
      @name = name
    end

    def self.banners
      hash = {}
      hash['default'] = Banner.new('default')
      hash
    end

    def ==(other)
      name == other.name
    end

    def motd
      config_get('banner', 'motd')
    end

    def motd=(val)
      if val.nil? && (motd != default_motd)
        config_set('banner', 'motd', state: 'no', motd: '')
      elsif !val.nil?
        config_set('banner',
                   'motd',
                   state: '',
                   motd:  "^#{val.gsub(/\n/, '\\n')}^")
      end
    end

    def default_motd
      config_get_default('banner', 'motd')
    end
  end # class
end # module
