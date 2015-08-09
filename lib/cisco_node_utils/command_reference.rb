# CommandReference module for testing.
#
# Copyright (c) 2014-2015 Cisco and/or its affiliates.
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

require 'yaml'

module CommandReference
  # Helper class to match product id with reference files.
  class CommandPlatformFile
    attr_reader :regex, :file

    def initialize(match_expression, reference_file)
      self.regex = match_expression
      self.file = reference_file
    end

    def regex=(expression)
      if expression.is_a? Regexp
        @regex = expression
      else
        raise ArgumentError
      end
    end

    def file=(file)
      if file.is_a? String
        @file = file
      else
        raise ArgumentError
      end
    end

    def match(product)
      @regex.match(product)
    end
  end

  # Control a reference for an attribute.
  class CmdRef
    attr_reader :feature
    attr_reader :name
    attr_reader :sources
    attr_reader :hash

    @@KEYS = %w(default_value
                config_set config_set_append
                config_get config_get_token config_get_token_append
                test_config_get test_config_get_regex test_config_result)

    def initialize(feature, name, ref, source)
      raise ArgumentError, "'#{ref}' is not a hash." unless ref.is_a? Hash

      @feature = feature
      @name = name
      @hash = {}

      @sources = []
      merge(ref, source)
    end

    # Overwrite values from more specific references.
    def merge(values, file)
      values.each { |key, value|
        unless @@KEYS.include?(key)
          raise "Unrecognized key #{key} for #{feature}, #{name} in #{file}"
        end
        if value.nil?
          # Some attributes can store an explicit nil.
          # Others treat this as unset (allowing a platform to override common).
          if key == "default_value"
            @hash[key] = value
          else
            @hash.delete(key)
          end
        else
          @hash[key] = value
        end
      }
      @sources << file
    end

    def convert_to_constant(value)
      # NOTE: This method is now deprecated and should not be used for future
      #       development.
      #
      # If value is a string and it is empty OR the first letter is lower case
      # then leave value untouched.
      # If value is a string and the first letter is uppercase this indicates
      # that it could be a constant in Ruby so attempt to convert it to a Constant.
      if value.is_a?(String) and not value.empty?
        if value[0].chr == value[0].chr.upcase
          begin
            value = Object.const_get(value) if Object.const_defined?(value)
          rescue NameError
            # debug("#{value} looks like a constant but is not")
          end
        end
      end
      value
    end

    def test_config_result(value)
      result = @hash["test_config_result"][value]
      convert_to_constant(result)
    end

    def method_missing(method_name, *args, &block)
      super(method_name, *args, &block) unless @@KEYS.include?(method_name.to_s)
      method_name = method_name.to_s
      unless @hash.include?(method_name)
        raise IndexError, "No #{method_name} defined for #{@feature}, #{@name}"
      end
      # puts("get #{method_name}: '#{@hash[method_name]}'")
      @hash[method_name]
    end

    # Print useful debugging information about the object.
    def to_s
      str = ""
      str << "Command: #{@feature} #{@name}\n"
      @hash.each { |key, value|
        str << "  #{key}: #{value}\n"
      }
      str
    end

    # Check that all necessary values have been populated.
    def valid?
      return false unless @feature and @name
      true
    end
  end

  # Builds reference hash for the platform specified in the product id.
  class CommandReference
    @@debug = false

    def self.debug
      @@debug
    end

    def self.debug=(value)
      raise ArgumentError, "Debug must be boolean" unless value == true or value == false
      @@debug = value
    end

    attr_reader :files, :product_id

    # Constructor.
    # Normal usage is to pass product_id only, in which case all usual YAML
    # files will be located then the list will be filtered down to only those
    # matching the given product_id.
    # For testing purposes (only!) you can pass an explicit list of files to
    # load instead. This list will NOT be filtered further by product_id.
    def initialize(product_id, files=nil)
      @product_id = product_id
      @hash = {}
      if files
        @files = files
      else
        @files = []
        # Hashes are unordered in Ruby 1.8.7. Instead, we use an array of objects.
        platforms = [
          CommandPlatformFile.new(//,
                                  File.join(File.dirname(__FILE__),
                                            "command_reference_common.yaml")),
          CommandPlatformFile.new(/N9K/,
                                  File.join(File.dirname(__FILE__),
                                            "command_reference_n9k.yaml")),
          CommandPlatformFile.new(/N7K/,
                                  File.join(File.dirname(__FILE__),
                                            "command_reference_n7k.yaml")),
          CommandPlatformFile.new(/C3064/,
                                  File.join(File.dirname(__FILE__),
                                            "command_reference_n3064.yaml")),
        ]
        # Build array
        platforms.each { |reference|
          @files << reference.file if reference.match(@product_id)
        }
      end

      build_cmd_ref
    end

    # Build complete reference hash.
    def build_cmd_ref
      # Example id's: N3K-C3048TP-1GE, N3K-C3064PQ-10GE, N7K-C7009, N7K-C7009

      debug "Product: #{@product_id}"
      debug "Files being used: #{@files.join(', ')}"

      reference_yaml = {}

      @files.each { |file|
        debug "Processing file '#{file}'"
        reference_yaml = load_yaml(file)

        reference_yaml.each { |feature, names|
          if names.nil? or names.empty?
            raise "No names under feature #{feature}: #{names}"
          elsif @hash[feature].nil?
            @hash[feature] = {}
          else
            debug "  Merging feature '#{feature}' retrieved from '#{file}'."
          end
          names.each { |name, values|
            debug "  Processing feature '#{feature}' name '#{name}'"
            if @hash[feature][name].nil?
              begin
                @hash[feature][name] = CmdRef.new(feature, name, values, file)
              rescue ArgumentError => e
                raise "Invalid data for '#{feature}', '#{name}': #{e}"
              end
            else
              debug "  Merging feature '#{feature}' name '#{name}' from '#{file}'."
              @hash[feature][name].merge(values, file)
            end
          }
        }
      }

      raise "Missing values in CommandReference." unless valid?
    end

    # Get the command reference
    def lookup(feature, name)
      begin
        value = @hash[feature][name]
      rescue NoMethodError
        # happens if @hash[feature] doesn't exist
        value = nil
      end
      if value.nil?
        raise IndexError, "No CmdRef defined for #{feature}, #{name}"
      end
      value
    end

    def empty?
      @hash.empty?
    end

    # Print debug statements
    def debug(text)
      puts "DEBUG: #{text}" if @@debug
    end

    def is_mapping?(node)
      # Need to handle both Syck::Map and Psych::Nodes::Mapping
      node.class.ancestors.any? { |name| /Map/ =~ name.to_s }
    end
    private :is_mapping?

    def get_keys_values_from_map(node)
      if node.class.ancestors.any? { |name| /Psych/ =~ name.to_s }
        # A Psych::Node::Mapping instance has an Array of children in
        # the format [key1, val1, key2, val2]
        key_children = node.children.select.each_with_index { |n, i| i.even? }
        val_children = node.children.select.each_with_index { |n, i| i.odd? }
      else
        # Syck::Map nodes have a .children method but it doesn't work :-(
        # Instead we access the node.value which is a hash.
        key_children = node.value.keys
        val_children = node.value.values
      end
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
      return unless node and (is_mapping?(node) or node.children)
      # Psych wraps everything in a Document instance, while
      # Syck does not. To keep the "depth" counting consistent,
      # we need to ignore Documents.
      depth += 1 unless node.class.ancestors.any? { |name| /Document/ =~ name.to_s }
      debug "Validating #{node.class} at depth #{depth}"

      # No special validation for non-mapping nodes - just recurse
      unless is_mapping?(node)
        node.children.each { |child|
          validate_yaml(child, filename, depth, parents)
        }
        return
      end

      # For Mappings, we validate more extensively:
      # 1. no duplicate keys are allowed (Syck/Psych don't catch this)
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
        raise msg
      end

=begin
# Syck does not necessarily preserve ordering of keys in a mapping even during
# the initial parsing stage. To avoid spurious failures, this is disabled
# for now. Fixing this may require restructuring our YAML...
      # Enforce alphabetical ordering of features (only).
      # We can extend this later to enforce ordering of names if desired
      # by checking at depth 2 as well.
      if depth == 1
        last_key = nil
        key_arr.each do |key|
          if last_key and key < last_key
            raise RuntimeError, "features out of order (#{last_key} > #{key})"
          end
          last_key = key
        end
      end
=end

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
    def load_yaml(yaml_file)
      raise "File #{yaml_file} doesn't exist." unless File.exist?(yaml_file)
      # Parse YAML file into a tree of nodes
      # Psych::SyntaxError doesn't inherit from StandardError in some versions,
      # so we want to explicitly catch it if using Psych.
      if defined?(::Psych::SyntaxError)
        rescue_errors = [::StandardError, ::Psych::SyntaxError]
      else
        rescue_errors = [::StandardError]
      end
      yaml_parsed = File.open(yaml_file, 'r') do |f|
        begin
          YAML.parse(f)
        rescue *rescue_errors => e
          raise "unable to parse #{yaml_file}: #{e}"
        end
      end
      if yaml_parsed
        # Validate the node tree
        validate_yaml(yaml_parsed, yaml_file)
        # If validation passed, convert the node tree to a Ruby Hash.
        return yaml_parsed.transform
      else
        # if yaml_file is empty, YAML.parse() returns false.
        # Change this to an empty hash.
        return {}
      end
    end

    # Check that all resources were pulled in correctly.
    def valid?
      complete_status = true
      @hash.each { |feature, names|
        names.each { |name, ref|
          status = ref.valid?
          debug "Reference does not contain all supported values:\n#{ref}" unless status
          complete_status = (status and complete_status)
        }
      }
      complete_status
    end

    def to_s
      @hash.each { |feature, names|
        names.each { |name, ref|
          ref.to_s
        }
      }
    end
  end
end
