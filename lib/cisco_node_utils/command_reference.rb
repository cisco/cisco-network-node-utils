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

require_relative 'exceptions'
require 'yaml'

module Cisco
  # Control a reference for an attribute.
  class CmdRef
    attr_reader :feature, :name, :hash
    attr_reader :auto_default, :multiple, :kind, :default_only
    alias_method :auto_default?, :auto_default
    alias_method :default_only?, :default_only
    alias_method :multiple?, :multiple

    KEYS = %w(default_value default_only
              data_format context value
              get_data_format get_command get_context get_value
              set_data_format set_context set_value
              auto_default multiple kind)

    def self.keys
      KEYS
    end

    KINDS = %w(boolean int string symbol)

    # Construct a CmdRef describing the given (feature, name) pair.
    # Param "values" is a hash with keys as described in KEYS.
    # Param "file" is for debugging purposes only.
    def initialize(feature, name, values, file)
      fail ArgumentError, "'#{values}' is not a hash." unless values.is_a? Hash

      @feature = feature
      @name = name
      @auto_default = true
      @default_only = false
      @multiple = false
      @kind = nil

      values_to_hash(values, file)

      if @hash['get_value'] || @hash['get_command']
        define_helper('getter',
                      data_format: @hash['get_data_format'] || :cli,
                      command:     @hash['get_command'],
                      context:     @hash['get_context'] || [],
                      value:       @hash['get_value'])
      end
      if @hash['set_value'] # rubocop:disable Style/GuardClause
        define_helper('setter',
                      data_format: @hash['set_data_format'] || :cli,
                      context:     @hash['set_context'] || [],
                      values:      @hash['set_value'])
      end
    end

    def values_to_hash(values, file)
      @hash = {}
      values.each do |key, value|
        unless KEYS.include?(key)
          fail "Unrecognized key #{key} for #{feature}, #{name} in #{file}"
        end
        case key
        when 'auto_default'
          @auto_default = value ? true : false
        when 'data_format', 'get_data_format', 'set_data_format'
          @hash[key] = value.to_sym
        when 'default_only'
          @default_only = true
          # default_value overrides default_only
          @hash['default_value'] ||= value
        when 'multiple'
          @multiple = boolean_default_true(value)
        when 'kind'
          fail "Unknown 'kind': '#{value}'" unless KINDS.include?(value)
          @kind = value.to_sym
        else
          # default_value overrides default_only
          @default_only = false if key == 'default_value'
          @hash[key] = value
        end
      end

      # Inherit general to specific if needed
      if @hash.key?('data_format')
        @hash['get_data_format'] = @hash['data_format'] \
          unless @hash.key?('get_data_format')
        @hash['set_data_format'] = @hash['data_format'] \
          unless @hash.key?('set_data_format')
      end
      if @hash.key?('context')
        @hash['get_context'] = @hash['context'] unless @hash.key?('get_context')
        @hash['set_context'] = @hash['context'] unless @hash.key?('set_context')
      end
      if @hash.key?('value')
        @hash['get_value'] = @hash['value'] unless @hash.key?('get_value')
        @hash['set_value'] = @hash['value'] unless @hash.key?('set_value')
      end

      @hash.delete_if { |key, _| key != 'default_value' } if @default_only
    end

    # Does this instance have a valid getter() function?
    # Will be overridden at initialization if so.
    def getter?
      !@hash['getter'].nil?
    end

    # Does this instance have a valid setter() function?
    # Will be overridden at initialization if so.
    def setter?
      !@hash['setter'].nil?
    end

    # Default getter method.
    # Will be overridden at initialization if the relevant parameters are set.
    #
    # A non-trivial implementation of this method will take args *or* kwargs,
    # and will return a hash of the form:
    # {
    #   data_format: :cli,
    #   command:     string or nil,
    #   context:     array<string> or array<regexp>, perhaps empty
    #   value:       string or regexp,
    # }
    def getter(*args, **kwargs) # rubocop:disable Lint/UnusedMethodArgument
      fail UnsupportedError.new(@feature, @name, 'getter')
    end

    # Default setter method.
    # Will be overridden at initialization if the relevant parameters are set.
    #
    # A non-trivial implementation of this method will take args *or* kwargs,
    # and will return a hash of the form:
    # {
    #   data_format: :cli,
    #   context:     array<string>, perhaps empty
    #   values:      array<string>,
    # }
    def setter(*args, **kwargs) # rubocop:disable Lint/UnusedMethodArgument
      fail UnsupportedError.new(@feature, @name, 'setter')
    end

    # Property with an implicit value of 'true' if no value is given
    def boolean_default_true(value)
      value.nil? || value
    end

    def key_substitutor(item, kwargs)
      result = item
      kwargs.each do |key, value|
        result = result.sub("<#{key}>", value.to_s)
      end
      unsub = result[/<(\S+)>/, 1]
      fail ArgumentError, \
           "No value specified for '#{unsub}' in '#{result}'" if unsub
      result
    end

    def printf_substitutor(item, args)
      item = sprintf(item, *args.shift(item.scan(/%/).length))
      [item, args]
    end

    # Create a helper method for generating the getter/setter values.
    # This method will automatically handle wildcard arguments.
    def define_helper(method_name, base_hash)
      # Which kind of wildcards (if any) do we need to support?
      combined = []
      base_hash.each_value do |v|
        combined += v if v.is_a?(Array)
        combined << v if v.is_a?(String)
      end
      key_value = combined.any? { |i| i.is_a?(String) && /<\S+>/ =~ i }
      printf = combined.any? { |i| i.is_a?(String) && /%/ =~ i }

      if key_value && printf
        fail 'Invalid mixture of key-value and printf wildcards ' \
             "in #{method_name}: #{combined}"
      elsif key_value
        define_key_value_helper(method_name, base_hash)
      elsif printf
        arg_count = combined.join.scan(/%/).length
        define_printf_helper(method_name, base_hash, arg_count)
      else
        # simple static token(s)
        define_static_helper(method_name, base_hash)
      end
      @hash[method_name] = true
    end

    def define_key_value_helper(method_name, base_hash)
      # Key-value substitution
      define_singleton_method method_name.to_sym do |*args, **kwargs|
        unless args.empty?
          fail ArgumentError, "#{method_name} requires keyword args, not "\
            'positional args'
        end
        result = {}
        base_hash.each do |k, v|
          if v.is_a?(String)
            v = key_substitutor(v, kwargs)
          elsif v.is_a?(Array)
            output = []
            v.each do |line|
              # Check for (?) flag indicating optional param
              optional_line = line[/^\(\?\)(.*)/, 1]
              if optional_line
                begin
                  line = key_substitutor(optional_line, kwargs)
                rescue ArgumentError # Unsubstituted key - OK to skip this line
                  next
                end
              else
                line = key_substitutor(line, kwargs)
              end
              output.push(line)
            end
            v = output
          end
          result[k] = v
        end
        result
      end
    end

    def define_printf_helper(method_name, base_hash, arg_count)
      define_singleton_method method_name.to_sym do |*args, **kwargs|
        unless kwargs.empty?
          fail ArgumentError, "#{method_name} requires positional args, not " \
            'keyword args'
        end
        unless args.length == arg_count
          fail ArgumentError, 'wrong number of arguments ' \
            "(#{args.length} for #{arg_count})"
        end

        result = {}
        base_hash.each do |k, v|
          if v.is_a?(String)
            v, args = printf_substitutor(v, args)
          elsif v.is_a?(Array)
            output = []
            v.each do |line|
              line, args = printf_substitutor(line, args)
              output.push(line)
            end
            v = output
          end
          result[k] = v
        end
        result
      end
    end

    def define_static_helper(method_name, base_hash)
      # rubocop:disable Lint/UnusedBlockArgument
      define_singleton_method method_name.to_sym do |*args, **kwargs|
        base_hash
      end
      # rubocop:enable Lint/UnusedBlockArgument
    end

    def convert_to_constant(value)
      # NOTE: This method is now deprecated and should not be used for future
      #       development.
      #
      # If value is a string and it is empty OR the first letter is lower case
      # then leave value untouched.
      # If value is a string and the first letter is uppercase this indicates
      # that it could be a constant in Ruby, so attempt to convert it
      # to a Constant.
      if value.is_a?(String) && !value.empty?
        if value[0].chr == value[0].chr.upcase
          begin
            value = Object.const_get(value) if Object.const_defined?(value)
          rescue NameError
            debug("'#{value}' is not a constant")
          end
        end
      end
      value
    end

    def method_missing(method_name, *args, &block)
      if KEYS.include?(method_name.to_s)
        # ref.foo -> return @hash[foo] or fail IndexError
        method_name = method_name.to_s
        unless @hash.include?(method_name)
          if @default_only
            fail UnsupportedError.new(@feature, @name, method_name)
          end
          fail IndexError, "No #{method_name} defined for #{@feature}, #{@name}"
        end
        # puts("get #{method_name}: '#{@hash[method_name]}'")
        @hash[method_name]
      elsif method_name.to_s[-1] == '?' && \
            KEYS.include?(method_name.to_s[0..-2])
        # ref.foo? -> return true if @hash[foo], else false
        method_name = method_name.to_s[0..-2]
        @hash.include?(method_name)
      else
        super(method_name, *args, &block)
      end
    end

    # Print useful debugging information about the object.
    def to_s
      str = ''
      str << "Command: #{@feature} #{@name}\n"
      @hash.each { |key, value| str << "  #{key}: #{value}\n" }
      str
    end
  end

  # Placeholder for known but explicitly excluded entry
  # For these, we have an implied default_only value of nil.
  class UnsupportedCmdRef < CmdRef
    def initialize(feature, name, file)
      super(feature, name, { 'default_only' => nil }, file)
    end
  end

  # Builds reference hash for the platform specified in the product id.
  class CommandReference
    @@debug = false # rubocop:disable Style/ClassVars

    def self.debug=(value)
      fail ArgumentError, 'Debug must be boolean' unless value == true ||
                                                         value == false
      @@debug = value # rubocop:disable Style/ClassVars
    end

    attr_reader :data_formats, :files, :platform, :product_id

    # Constructor.
    # Normal usage is to pass product, platform, data_formats,
    # in which case usual YAML files will be located then the list
    # will be filtered down to only those matching the given settings.
    # For testing purposes (only!) you can pass an explicit list of files to
    # load instead. This list will NOT be filtered further by product_id.
    def initialize(product:      nil,
                   platform:     nil,
                   data_formats: [],
                   files:        nil)
      @product_id = product
      @platform = platform
      @data_formats = data_formats
      @hash = {}
      if files
        @files = files
      else
        @files = Dir.glob(__dir__ + '/cmd_ref/*.yaml')
      end

      build_cmd_ref
    end

    # Build complete reference hash.
    def build_cmd_ref
      # Example id's: N3K-C3048TP-1GE, N3K-C3064PQ-10GE, N7K-C7009, N7K-C7009
      debug "Product: #{@product_id}"
      debug "Files being used: #{@files.join(', ')}"

      @files.each do |file|
        feature = File.basename(file).split('.')[0]
        debug "Processing file '#{file}' as feature '#{feature}'"
        feature_hash = load_yaml(file)
        if feature_hash.empty?
          debug "Feature #{feature} is empty"
          next
        end
        begin
          feature_hash = filter_hash(feature_hash)
        rescue RuntimeError => e
          raise "#{file}: #{e}"
        end
        if feature_hash.empty?
          debug "Feature #{feature} is excluded"
          @hash[feature] = UnsupportedCmdRef.new(feature, nil, file)
          next
        end

        base_hash = {}
        if feature_hash.key?('_template')
          base_hash = CommandReference.hash_merge(feature_hash['_template'])
        end

        feature_hash.each do |name, value|
          fail "No entries under '#{name}' in '#{file}'" if value.nil?
          @hash[feature] ||= {}
          if value.empty?
            @hash[feature][name] = UnsupportedCmdRef.new(feature, name, file)
          else
            values = CommandReference.hash_merge(value, base_hash.clone)
            @hash[feature][name] = CmdRef.new(feature, name, values, file)
          end
        end
      end
    end

    def supports?(feature, property=nil)
      value = @hash[feature]
      value = value[property] if value.is_a?(Hash) && property
      !(value.is_a?(UnsupportedCmdRef) || value.nil?)
    end

    # Get the command reference
    def lookup(feature, name)
      value = @hash[feature]
      value = value[name] if value.is_a? Hash
      fail IndexError, "No CmdRef defined for #{feature}, #{name}" if value.nil?
      value
    end

    def empty?
      @hash.empty?
    end

    # Print debug statements
    def debug(text)
      puts "DEBUG: #{text}" if @@debug
    end

    KNOWN_PLATFORMS = %w(C3064 C3132 C3172 N3k N5k N6k N7k N9k N9k-F XRv9k)

    def self.platform_to_filter(platform)
      if KNOWN_PLATFORMS.include?(platform)
        case platform
        when 'XRv9k'
          /XRV9/
        when 'N9k'
          # For non-fretta n9k platforms we need to
          # match everything except the trailing -F
          /^N9...(?!.*-F)/
        when 'N9k-F'
          # For fretta n9k we need to include the trailing -F
          /^N9.*-F$/
        else
          Regexp.new platform.tr('k', '')
        end
      else
        fail IndexError, "Unknown platform key '#{platform}'"
      end
    end

    KNOWN_FILTERS = %w(nexus ios_xr cli nxapi_structured)

    def self.key_match(key, platform, product_id, data_formats)
      if KNOWN_PLATFORMS.include?(key)
        return platform_to_filter(key) =~ product_id ? true : false
      elsif KNOWN_FILTERS.include?(key)
        return true if data_formats && data_formats.include?(key.to_sym)
        return true if key == platform.to_s
        return false
      else
        return :unknown
      end
    end

    # Helper method
    # Given a Hash of command reference data as read from YAML, does:
    # - Delete any platform-specific data not applicable to this platform
    # - Delete any product-specific data not applicable to this product_id
    # - Delete any data-model-specific data not supported by this node
    # Returns the filtered hash (possibly empty)
    def self.filter_hash(hash,
                         platform:           nil,
                         product_id:         nil,
                         data_formats:       nil,
                         allow_unknown_keys: true)
      result = {}

      exclude = hash['_exclude'] || []
      exclude.each do |value|
        # We don't allow exclusion by data_format - just platform/product
        if key_match(value, platform, product_id, nil) == true
          debug "Exclude this product (#{product_id}, #{value})"
          return result
        end
      end

      # to_inspect: sub-keys we want to recurse into
      to_inspect = []
      # regexp_match: did we find a product_id regexp that matches?
      regexp_match = false

      hash.each do |key, value|
        next if key == '_exclude'
        if CmdRef.keys.include?(key)
          result[key] = value
        elsif key != 'else'
          match = key_match(key, platform, product_id, data_formats)
          next if match == false
          if match == :unknown
            fail "Unrecognized key '#{key}'" unless allow_unknown_keys
          end
          regexp_match = true if match == true
          to_inspect << key
        end
      end
      # If we didn't find any platform regexp match,
      # and an 'else' sub-hash is provided, descend into 'else'
      to_inspect << 'else' if hash.key?('else') && !regexp_match
      # Recurse! Sub-hashes can override the base hash
      to_inspect.each do |key|
        unless hash[key].is_a?(Hash)
          result[key] = hash[key]
          next
        end
        begin
          result[key] = filter_hash(hash[key],
                                    platform:           platform,
                                    product_id:         product_id,
                                    data_formats:       data_formats,
                                    allow_unknown_keys: false)
        rescue RuntimeError => e
          # Recursively wrap the error as needed to provide context
          raise "[#{key}]: #{e}"
        end
      end
      result
    end

    def filter_hash(input_hash)
      CommandReference.filter_hash(input_hash,
                                   platform:     platform,
                                   product_id:   product_id,
                                   data_formats: data_formats)
    end

    # Helper method
    # Given a suitably filtered Hash of command reference data, does:
    # - Inherit data from the given base_hash (if any) and extend/override it
    #   with the given input data.
    def self.hash_merge(input_hash, base_hash=nil)
      return base_hash if input_hash.nil?
      result = base_hash
      result ||= {}
      # to_inspect: sub-hashes we want to recurse into
      to_inspect = []

      input_hash.each do |key, value|
        if CmdRef.keys.include?(key)
          result[key] = value
        elsif value.is_a?(Hash)
          to_inspect << value
        elsif value.nil?
          next
        else
          fail "Unexpected non-hash data: #{value}"
        end
      end
      # Recurse! Sub-hashes can override the base hash
      to_inspect.each do |hash|
        result = hash_merge(hash, result)
      end
      result
    end

    # Helper method.
    # Combines the two given values (either or both of which may be arrays)
    # into a single combined array
    # value_append('foo', 'bar') ==> ['foo', 'bar']
    # value_append('foo', ['bar', 'baz']) ==> ['foo', 'bar', 'baz']
    def self.value_append(base_value, new_value)
      base_value = [base_value] unless base_value.is_a?(Array)
      new_value = [new_value] unless new_value.is_a?(Array)
      base_value + new_value
    end

    def mapping?(node)
      node.class.ancestors.any? { |name| /Map/ =~ name.to_s }
    end
    private :mapping?

    def get_keys_values_from_map(node)
      # A Psych::Node::Mapping instance has an Array of children in
      # the format [key1, val1, key2, val2]
      key_children = node.children.select.each_with_index { |_, i| i.even? }
      val_children = node.children.select.each_with_index { |_, i| i.odd? }
      debug "children of #{node} mapping: #{key_children}, #{val_children}"
      [key_children, val_children]
    end
    private :get_keys_values_from_map

    # Validate the YAML node tree before converting it into Ruby
    # data structures.
    #
    # @raise RuntimeError if the node tree is not valid by our constraints.
    #
    # @param node Node to be validated, then recurse to its children.
    # @param filename File that YAML was parsed from, for messages
    # @param depth Depth into the node tree
    # @param parents String describing parents of this node, for messages
    def validate_yaml(node, filename, depth=0, parents=nil)
      return unless node && (mapping?(node) || node.children)
      # Psych wraps everything in a Document instance, which we ignore.
      unless node.class.ancestors.any? { |name| /Document/ =~ name.to_s }
        depth += 1
      end
      debug "Validating #{node.class} at depth #{depth}"

      # No special validation for non-mapping nodes - just recurse
      unless mapping?(node)
        node.children.each do |child|
          validate_yaml(child, filename, depth, parents)
        end
        return
      end

      # For Mappings, we validate more extensively:
      # 1. no duplicate keys are allowed (Psych doesn't catch this)
      # 2. Features must be listed in alphabetical order for maintainability

      # Take advantage of our known YAML structure to assign labels by depth
      label = %w(feature name param).fetch(depth, 'key')

      # Get the key nodes and value nodes under this mapping
      key_children, val_children = get_keys_values_from_map(node)
      # Get an array of key names
      key_arr = key_children.map(&:value)

      # Make sure no duplicate key names.
      # If searching from the start of the array finds a name at one index,
      # but searching from the end of the array finds it at a different one,
      # then we have a duplicate.
      dup = key_arr.detect { |e| key_arr.index(e) != key_arr.rindex(e) }
      if dup
        msg = "Duplicate #{label} '#{dup}'#{parents} in #{filename}!"
        fail msg
      end

      # Enforce alphabetical ordering of features (only).
      # We can extend this later to enforce ordering of names if desired
      # by checking at depth 2 as well.
      if depth == 1
        last_key = nil
        key_arr.each do |key|
          if last_key && key < last_key
            fail "features out of order in #{filename}: (#{last_key} > #{key})"
          end
          last_key = key
        end
      end

      # Recurse to the children. We get a little fancy here so as to be able
      # to provide more meaningful debug/error messages, such as:
      # Duplicate param 'default_value' under feature 'foo', name 'bar'
      key_children.zip(val_children).each do |key_node, val_node|
        if parents
          new_parents = parents + ", #{label} '#{key_node.value}'"
        else
          new_parents = " under #{label} '#{key_node.value}'"
        end
        validate_yaml(key_node, filename, depth, new_parents) # unnecessary?
        validate_yaml(val_node, filename, depth, new_parents)
      end
    end
    private :validate_yaml

    # Read in yaml file.
    # The expectation is that a file corresponds to a feature
    def load_yaml(yaml_file)
      fail "File #{yaml_file} doesn't exist." unless File.exist?(yaml_file)
      # Parse YAML file into a tree of nodes
      # Psych::SyntaxError doesn't inherit from StandardError in some versions,
      # so we want to explicitly catch it if using Psych.
      rescue_errors = [::StandardError, ::Psych::SyntaxError]
      yaml_parsed = File.open(yaml_file, 'r') do |f|
        begin
          YAML.parse(f)
        rescue *rescue_errors => e
          raise "unable to parse #{yaml_file}: #{e}"
        end
      end
      return {} unless yaml_parsed
      # Validate the node tree
      validate_yaml(yaml_parsed, yaml_file)
      # If validation passed, convert the node tree to a Ruby Hash.
      yaml_parsed.transform
    end

    def to_s
      @num_features ||= @hash.values.length
      @num_attributes ||= @hash.values.inject(0) do |sum, n|
        sum + (n.is_a?(Hash) ? n.values.length : 1)
      end
      "CommandReference describing #{@num_features} features " \
        "with #{@num_attributes} attributes in total"
    end

    def inspect
      "CommandReference for '#{product_id}' " \
        "(platform:'#{platform}', data formats:#{data_formats}) " \
        "based on #{files.length} files"
    end
  end
end
