# Tacacs Global provider class

# TP HONEY et al., June 2014-2017

# Copyright (c) 2014-2017 Cisco and/or its affiliates.

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

# Tacacs Global configuration management
module Cisco
  # TacacsGlobal - node utility class for
  class TacacsGlobal < NodeUtil
    attr_reader :name

    def initialize(name)
      fail TypeError unless name.is_a?(String)
      fail ArgumentError,
           "This provider only accepts an id of 'default'" \
           unless name.eql?('default')
      @name = name
    end

    def self.tacacs_global
      hash = {}
      hash['default'] = TacacsGlobal.new('default')
      hash
    end

    def ==(other)
      name == other.name
    end

    def timeout
      return nil unless Feature.tacacs_enabled?
      config_get('tacacs_global', 'timeout')
    end

    def default_timeout
      config_get_default('tacacs_global', 'timeout')
    end

    def timeout=(val)
      unless val.nil?
        fail ArgumentError, 'timeout must be an Integer' \
          unless val.is_a?(Integer)
      end

      if val.nil?
        fail ArgumentError, 'timeout cannot be unset if TACACS enabled - ' \
        "use default value #{default_timeout}" \
          if Feature.tacacs_enabled?
      else
        Feature.tacacs_enable
        config_set('tacacs_global',
                   'timeout',
                   state:   '',
                   timeout: val)
      end
    end

    def key_format
      match = config_get('tacacs_global', 'key_format')
      match.nil? ? TACACS_GLOBAL_ENC_UNKNOWN : match[0].to_i
    end

    def key
      return nil unless Feature.tacacs_enabled?
      str = config_get('tacacs_global', 'key')
      return TacacsGlobal.default_key if str.empty?
      str = str[1].strip
      Utils.add_quotes(str)
    end

    # Get default encryption password
    def self.default_key
      config_get_default('tacacs_global', 'key')
    end

    def encryption_key_set(key_format, key)
      # If we get an empty key - remove default if configured
      if key.nil? || key.to_s.empty?
        key = self.key
        return if key.empty?
        key_format = self.key_format
        config_set('tacacs_server', 'encryption', state: 'no',
                    option: key_format, key: key)
      else
        Feature.tacacs_enable
        key = Utils.add_quotes(key)
        if key_format.nil? || key_format.to_s.empty?
          config_set('tacacs_server', 'encryption', state: '', option: '',
                    key: key)
        else
          config_set('tacacs_server', 'encryption', state: '',
                    option: key_format, key: key)
        end
      end
    end

    # Get default source interface
    def default_source_interface
      config_get_default('tacacs_global', 'source_interface')
    end

    # Set source interface
    def source_interface=(name)
      if name
        Feature.tacacs_enable
        config_set(
          'tacacs_global', 'source_interface',
          state: '', source_interface: name)
      else
        config_set(
          'tacacs_global', 'source_interface',
          state: 'no', source_interface: '')
      end
    end

    # Get source interface
    def source_interface
      return nil unless Feature.tacacs_enabled?
      i = config_get('tacacs_global', 'source_interface')
      i.nil? ? default_source_interface : i.downcase
    end
  end # class
end # module
