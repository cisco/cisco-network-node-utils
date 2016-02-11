# Radius Global provider class

# Jonathan Tripathy et al., September 2015

# Copyright (c) 2014-2016 Cisco and/or its affiliates.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require_relative 'node_util'

module Cisco
  # RadiusGlobal - node utility class for
  # Radius Global configuration management
  class RadiusGlobal < NodeUtil
    attr_reader :name

    def initialize(name)
      fail TypeError unless name.is_a?(String)
      fail ArgumentError,
           "This provider only accepts an id of 'default'" \
           unless name.eql?('default')
      @name = name
    end

    def self.radius_global
      hash = {}
      hash['default'] = RadiusGlobal.new('default')
      hash
    end

    def ==(other)
      name == other.name
    end

    def timeout
      config_get('radius_global', 'timeout')
    end

    def default_timeout
      config_get_default('radius_global', 'timeout')
    end

    def timeout=(val)
      unless val.nil?
        fail ArgumentError, 'timeout must be an Integer' \
          unless val.is_a?(Integer)
      end

      if val.nil?
        config_set('radius_global',
                   'timeout',
                   state:   'no',
                   timeout: timeout)
      else
        config_set('radius_global',
                   'timeout',
                   state:   '',
                   timeout: val)
      end
    end

    def retransmit_count
      config_get('radius_global', 'retransmit')
    end

    def default_retransmit_count
      config_get_default('radius_global', 'retransmit').to_i
    end

    def retransmit_count=(val)
      unless val.nil?
        fail ArgumentError, 'retransmit_count must be an Integer' \
          unless val.is_a?(Integer)
      end

      if val.nil?
        config_set('radius_global',
                   'retransmit',
                   state: 'no',
                   count: retransmit_count)
      else
        config_set('radius_global',
                   'retransmit',
                   state: '',
                   count: val)
      end
    end

    def key_format
      config_get('radius_global', 'key_format')
    end

    def key
      config_get('radius_global', 'key')
    end

    def key_set(value, format)
      unless value.nil?
        fail ArgumentError, 'value must be a String' \
          unless value.is_a?(String)
      end

      unless format.nil?
        fail ArgumentError, 'format must be an Integer' \
          unless format.is_a?(Integer)
      end

      if value.nil? && !key.nil?
        config_set('radius_global',
                   'key',
                   state: 'no',
                   key:   "#{key_format} #{key}")
      elsif !format.nil?
        config_set('radius_global',
                   'key',
                   state: '',
                   key:   "#{format} #{value}")
      else
        config_set('radius_global',
                   'key',
                   state: '',
                   key:   "#{value}")
      end
    end
  end # class
end # module
