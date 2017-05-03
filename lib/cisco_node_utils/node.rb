# Cisco node helper class. Abstracts away the details of the underlying
# transport (whether NXAPI or some other future transport) and provides
# various convenient helper methods.
#
# December 2014, Glenn F. Matthews
#
# Copyright (c) 2014-2017 Cisco and/or its affiliates.
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

require_relative 'client'
require_relative 'command_reference'
require_relative 'exceptions'
require_relative 'logger'

# Add node management classes and APIs to the Cisco namespace.
module Cisco
  # class Cisco::Node
  # Singleton representing the network node (switch/router) that is
  # running this code. The singleton is lazily instantiated, meaning that
  # it doesn't exist until some client requests it (with Node.instance())
  class Node
    @instance = nil

    # Convenience wrapper for get()
    # Uses CommandReference to look up the given show command and key
    # of interest, executes that command, and returns the value corresponding
    # to that key.
    #
    # @raise [IndexError] if the given (feature, name) pair is not in the
    #        CommandReference data or if the data doesn't have values defined
    #        for the 'get_command' and (optional) 'get_value' fields.
    # @raise [Cisco::UnsupportedError] if the (feature, name) pair is flagged
    #        in the YAML as unsupported on this device.
    # @raise [Cisco::RequestFailed] if the command is rejected by the device.
    #
    # @param feature [String]
    # @param name [String]
    # @return [String, Hash, Array]
    # @example config_get("show_version", "system_image")
    # @example config_get("ospf", "router_id",
    #                     {name: "green", vrf: "one"})
    def config_get(feature, property, *args)
      ref = @cmd_ref.lookup(feature, property)

      # If we have a default value but no getter, just return the default
      return ref.default_value if ref.default_value? && !ref.getter?

      get_args, ref = massage_structured(ref.getter(*args).clone, ref)
      data = get(command:     get_args[:command],
                 data_format: get_args[:data_format],
                 context:     get_args[:context],
                 value:       get_args[:value])
      massage(data, ref)
    end

    # The yaml file may specifiy an Array as the get_value to drill down into
    # nxapi_structured table output.  The table may contain multiple rows but
    # only one of the rows has the interesting data.
    def massage_structured(get_args, ref)
      # Nothing to do unless nxapi_structured.
      return [get_args, ref] unless
        ref.hash['get_data_format'] == :nxapi_structured

      # The CmdRef object will contain a get_value Array with 2 values.
      # The first value is the key to identify the correct row in the table
      # of structured output and the second is the key to identify the data
      # to retrieve.
      #
      # Example: Get vlanshowbr-vlanname in the row that contains a specific
      #  vlan_id.
      # "get_value"=>["vlanshowbr-vlanid-utf <vlan_id>", "vlanshowbr-vlanname"]
      #
      # TBD: Why do we need to check is_a?(Array) here?
      if ref.hash['get_value'].is_a?(Array) && ref.hash['get_value'].size >= 2
        # Replace the get_value hash entry with the value after any tokens
        # specified in the yaml file have been replaced and set get_args[:value]
        # to nil so that the structured table data can be retrieved properly.
        ref.hash['get_value'] = get_args[:value]
        ref.hash['drill_down'] = true
        get_args[:value] = nil
        cache_flush
      end
      [get_args, ref]
    end

    # Drill down into structured nxapi table data and return value from the
    # row specified by a two part key.
    #
    # Example: Get vlanshowbr-vlanname in the row that contains vlan id 1000
    # "get_value"=>["vlanshowbr-vlanid-utf 1000", "vlanshowbr-vlanname"]
    # Example with optional regexp match
    # "get_value"=>["vlanshowbr-vlanid-utf 1000", "vlanshowbr-vlanname",
    #                '/^shutdown$/']
    def drill_down_structured(value, ref)
      # Nothing to do unless nxapi_structured
      return value unless ref.hash['drill_down']

      row_key = ref.hash['get_value'][0][/^\S+/]

      # Escape special characters if any in row_index and add
      # anchors for exact match.
      row_index = Regexp.escape(ref.hash['get_value'][0][/\S+$/])
      row_index = "^#{row_index}$"

      data_key = ref.hash['get_value'][1]
      regexp_filter = nil
      if ref.hash['get_value'][2]
        regexp_filter = Regexp.new ref.hash['get_value'][2][1..-2]
      end
      # Get the value using the row_key, row_index and data_key
      value = value.is_a?(Hash) ? [value] : value
      data = nil
      value.each do |row|
        data = row[data_key] if row[row_key].to_s[/#{row_index}/]
      end
      return value if data.nil?
      if regexp_filter
        filtered = regexp_filter.match(data)
        return filtered.nil? ? filtered : filtered[filtered.size - 1]
      end
      data
    end

    # Attempt to massage the given value into the format specified by the
    # given CmdRef object.
    def massage(value, ref)
      Cisco::Logger.debug "Massaging '#{value}' (#{value.inspect})"
      value = drill_down_structured(value, ref)
      if value.is_a?(Array) && !ref.multiple
        fail "Expected zero/one value but got '#{value}'" if value.length > 1
        value = value[0]
      end
      if (value.nil? || value.to_s.empty?) &&
         ref.default_value? && ref.auto_default
        Cisco::Logger.debug "Default: #{ref.default_value}"
        return ref.default_value
      end
      if ref.multiple && ref.hash['get_data_format'] == :nxapi_structured
        return value if value.nil?
        value = [value.to_s] if value.is_a?(String) || value.is_a?(Fixnum)
      end
      return value unless ref.kind
      value = massage_kind(value, ref)
      Cisco::Logger.debug "Massaged to '#{value}'"
      value
    end

    def massage_kind(value, ref)
      case ref.kind
      when :boolean
        if value.nil? || value.empty?
          value = false
        elsif /^no / =~ value
          value = false
        elsif /disable$/ =~ value
          value = false
        else
          value = true
        end
      when :int
        value = value.to_i unless value.nil?
      when :string
        value = '' if value.nil?
        value = value.to_s.strip
      when :symbol
        value = value.to_sym unless value.nil?
      end
      value
    end

    # Uses CommandReference to lookup the default value for a given
    # feature and feature property.
    #
    # @raise [IndexError] if the given (feature, name) pair is not in the
    #        CommandReference data or if the data doesn't have values defined
    #        for the 'default_value' field.
    # @param feature [String]
    # @param name [String]
    # @return [String]
    # @return [nil] if this feature/name pair is marked as unsupported
    # @example config_get_default("vtp", "file")
    def config_get_default(feature, property)
      ref = @cmd_ref.lookup(feature, property)
      ref.default_value
    end

    # Uses CommandReference to look up the given config command(s) of interest
    # and then applies the configuration.
    #
    # @raise [IndexError] if no relevant cmd_ref config_set exists
    # @raise [ArgumentError] if too many or too few args are provided.
    # @raise [Cisco::UnsupportedError] if this feature/name is unsupported
    # @raise [Cisco::RequestFailed] if any command is rejected by the device.
    #
    # @param feature [String]
    # @param name [String]
    # @param args [*String] zero or more args to be substituted into the cmdref.
    # @example config_set("vtp", "domain", "example.com")
    # @example config_set("ospf", "router_id",
    #  {:name => "green", :vrf => "one", :state => "",
    #   :router_id => "192.0.0.1"})
    def config_set(feature, property, *args)
      ref = @cmd_ref.lookup(feature, property)
      set_args = ref.setter(*args)
      set(**set_args)
    end

    # Clear the cache of CLI output results.
    #
    # If cache_auto is true (default) then this will be performed automatically
    # whenever a config_set() is called, but providers may also call this
    # to explicitly force the cache to be cleared.
    def cache_flush
      @client.cache_flush
    end

    # Here and below are implementation details and private APIs that most
    # providers shouldn't need to know about or use.

    attr_reader :cmd_ref, :client

    def self.instance
      @instance ||= new
    end

    def initialize
      @client = Cisco::Client.create
      @cmd_ref = nil
      @cmd_ref = CommandReference.new(product:      product_id,
                                      platform:     @client.platform,
                                      data_formats: @client.data_formats)
      cache_flush
    end

    def to_s
      client.to_s
    end

    def inspect
      "Node: client:'#{client.inspect}' cmd_ref:'#{cmd_ref.inspect}'"
    end

    def cache_enable?
      @client.cache_enable?
    end

    def cache_enable=(enable)
      @client.cache_enable = enable
    end

    def cache_auto?
      @client.cache_auto?
    end

    def cache_auto=(enable)
      @client.cache_auto = enable
    end

    # Send a config command to the device.
    # In general, clients should use config_set() rather than calling
    # this function directly.
    #
    # @raise [Cisco::RequestFailed] if any command is rejected by the device.
    def set(**kwargs)
      @client.set(**kwargs)
    end

    # Send a show command to the device.
    # In general, clients should use config_get() rather than calling
    # this function directly.
    #
    # @raise [Cisco::RequestFailed] if any command is rejected by the device.
    def get(**kwargs)
      @client.get(**kwargs)
    end

    # Merge the specified JSON YANG config with the running config on
    # the device.
    def merge_yang(yang)
      @client.set(data_format: :yang_json, values: [yang], mode: :merge_config)
    end

    # Replace the running config on the device with the specified
    # JSON YANG config.
    def replace_yang(yang)
      @client.set(data_format: :yang_json, values: [yang],
                  mode: :replace_config)
    end

    # Delete the specified JSON YANG config from the device.
    def delete_yang(yang)
      @client.set(data_format: :yang_json, values: [yang], mode: :delete_config)
    end

    # Retrieve JSON YANG config from the device for the specified path.
    def get_yang(yang_path)
      @client.get(data_format: :yang_json, command: yang_path)
    end

    # Retrieve JSON YANG operational data for the specified path.
    def get_yang_oper(yang_path)
      @client.get(data_format: :yang_json, command: yang_path, mode: :get_oper)
    end

    # @return [String] such as "Cisco Nexus Operating System (NX-OS) Software"
    def os
      o = config_get('show_version', 'header')
      fail 'failed to retrieve operating system information' if o.nil?
      o.split("\n")[0]
    end

    # @return [String] such as "6.0(2)U5(1) [build 6.0(2)U5(0.941)]"
    def os_version
      config_get('show_version', 'version')
    end

    # @return [String] such as "Nexus 3048 Chassis"
    def product_description
      config_get('show_version', 'description')
    end

    # @return [String] such as "N3K-C3048TP-1GE"
    def product_id
      if @cmd_ref
        prod = config_get('inventory', 'productid')
        all  = config_get('inventory', 'all')
        prod_qualifier(prod, all)
      else
        # We use this function to *find* the appropriate CommandReference
        if @client.platform == :nexus
          entries = get(command:     'show inventory',
                        data_format: :nxapi_structured)
          prod = entries['TABLE_inv']['ROW_inv'][0]['productid']
          prod_qualifier(prod, entries['TABLE_inv']['ROW_inv'])
        elsif @client.platform == :ios_xr
          # No support for structured output for this command yet
          output = get(command:     'show inventory',
                       data_format: :cli)
          return /NAME: .*\nPID: (\S+)/.match(output)[1]
        end
      end
    end

    def prod_qualifier(prod, inventory)
      case prod
      when /N9K/
        # Two datapoints are used to determine if the current n9k
        # platform is a fretta based n9k or non-fretta.
        #
        # 1) Image Version == 7.0(3)F*
        # 2) Fabric Module == N9K-C9*-FM-R
        if @cmd_ref
          ver = os_version
        else
          ver = get(command:     'show version',
                    data_format: :nxapi_structured)['kickstart_ver_str']
        end
        # Append -F for fretta platform.
        inventory.each do |row|
          if row['productid'][/N9K-C9...-FM-R/] && ver[/7.0\(3\)F/]
            return prod.concat('-F') unless prod[/-F/]
          end
        end
      end
      prod
    end

    # @return [String] such as "V01"
    def product_version_id
      config_get('inventory', 'versionid')
    end

    # @return [String] such as "FOC1722R0ET"
    def product_serial_number
      config_get('inventory', 'serialnum')
    end

    # @return [String] such as "bxb-oa-n3k-7"
    def host_name
      config_get('show_version', 'host_name')
    end

    # @return [String] such as "example.com"
    def domain_name
      config_get('dnsclient', 'domain_name')
    end

    # @return [Integer] System uptime, in seconds
    def system_uptime
      cache_flush
      t = config_get('show_system', 'uptime')
      fail 'failed to retrieve system uptime' if t.nil?
      # time units: t = ["0", "23", "15", "49"]
      t.map!(&:to_i)
      d, h, m, s = t
      (s + 60 * (m + 60 * (h + 24 * (d))))
    end

    # @return [String] timestamp of last reset time
    def last_reset_time
      config_get('show_version', 'last_reset_time')
    end

    # @return [String] such as "Reset Requested by CLI command reload"
    def last_reset_reason
      config_get('show_version', 'last_reset_reason')
    end

    # @return [Float] combined user/kernel CPU utilization
    def system_cpu_utilization
      output = config_get('system', 'resources')
      return output if output.nil?
      output['cpu_state_user'].to_f + output['cpu_state_kernel'].to_f
    end

    # @return [String] such as
    #   "bootflash:///n3000-uk9-kickstart.6.0.2.U5.0.941.bin"
    def boot
      config_get('show_version', 'boot_image')
    end

    # @return [String] such as
    #   "bootflash:///n3000-uk9.6.0.2.U5.0.941.bin"
    def system
      config_get('show_version', 'system_image')
    end

    def os_version_get(feature, property)
      @cmd_ref.lookup(feature, property).os_version
    end
  end
end
