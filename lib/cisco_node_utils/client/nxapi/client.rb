# NXAPI client library.
#
# November 2014, Glenn F. Matthews
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

require_relative '../core'
require 'json'
require 'net/http'
require_relative 'client_errors'

include Cisco::Logger

# Namespace for all NXAPI-related functionality and classes.
module Cisco::Client::NXAPI
  # Location of unix domain socket for NXAPI localhost
  NXAPI_UDS = '/tmp/nginx_local/nginx_1_be_nxapi.sock'
  # NXAPI listens for remote connections to "http://<switch IP>/ins"
  # NXAPI listens for local connections to "http://<UDS>/ins_local"
  NXAPI_REMOTE_URI_PATH = '/ins'
  NXAPI_UDS_URI_PATH = '/ins_local'
  # Latest supported version is 1.0
  NXAPI_VERSION = '1.0'

  # Class representing an HTTP client connecting to a NXAPI server.
  class Client < Cisco::Client::Client
    Cisco::Client.register_client(self)

    # Constructor for Client. By default this connects to the local
    # unix domain socket. If you need to connect to a remote device,
    # you must provide the address/username/password parameters.
    def initialize(address=nil, username=nil, password=nil)
      super
      # Default: connect to unix domain socket on localhost, if available
      if address.nil?
        unless File.socket?(NXAPI_UDS)
          fail Cisco::Client::ConnectionRefused, \
               "No address specified but no UDS found at #{NXAPI_UDS} either"
        end
        # net_http_unix provides NetX::HTTPUnix, a small subclass of Net::HTTP
        # which supports connection to local unix domain sockets. We need this
        # in order to run natively under NX-OS but it's not needed for off-box
        # unit testing where the base Net::HTTP will meet our needs.
        require 'net_http_unix'
        @http = NetX::HTTPUnix.new('unix://' + NXAPI_UDS)
      else
        # Remote connection. This is primarily expected
        # when running e.g. from a Unix server as part of Minitest.
        @http = Net::HTTP.new(address)
      end
      # The default read time out is 60 seconds, which may be too short for
      # scaled configuration to apply. Change it to 300 seconds, which is
      # also used as the default config by firefox.
      @http.read_timeout = 300
      @address = @http.address
      @platform = :nexus

      # Make sure we can actually connect to the socket
      show('show hostname')
    end

    def validate_args(address, username, password)
      super
      if address.nil?
        # Connection to UDS - no username or password either
        fail ArgumentError unless username.nil? && password.nil?
      else
        fail ArgumentError, 'no port number permitted' if address =~ /:/
        # Connection to remote system - username and password are required
        fail TypeError, 'username is required' if username.nil?
        fail TypeError, 'password is required' if password.nil?
      end
    end

    def supports?(api)
      (api == :cli)
    end

    def reload
      # no-op for now
    end

    # Clear the cache of CLI output results.
    #
    # If cache_auto is true (default) then this will be performed automatically
    # whenever a config() or exec() is called, but providers may also call this
    # to explicitly force the cache to be cleared.
    def cache_flush
      @cache_hash = {
        'cli_conf'       => {},
        'cli_show'       => {},
        'cli_show_ascii' => {},
      }
    end

    # Configure the given command(s) on the device.
    #
    # @raise [CliError] if any command is rejected by the device
    #
    # @param commands [String, Array<String>] either of:
    #   1) The configuration sequence, as a newline-separated string
    #   2) An array of command strings (one command per string, no newlines)
    def config(commands)
      super
      if commands.is_a?(String)
        commands = commands.split(/\n/)
      elsif !commands.is_a?(Array)
        fail TypeError
      end
      req('cli_conf', commands)
    end

    # Executes a command in exec mode on the device.
    #
    # If cache_auto? (on by default) is set then the CLI cache will be flushed.
    #
    # For "show" commands please use show() instead of exec().
    #
    # @param command [String] the exec command to execute
    # @return [String, nil] the body of the output of the exec command
    #   (if any)
    def exec(command)
      super
      req('cli_show_ascii', command)
    end

    # Executes a "show" command on the device, returning either ASCII or
    # structured output.
    #
    # Unlike config() and exec() this will not clear the CLI cache;
    # multiple calls to the same "show" command may return cached data
    # rather than querying the device repeatedly.
    #
    # @raise [RequestNotSupported] if
    #   structured output is requested but the given command can't provide it.
    # @raise [CliError] if the command is rejected by the device
    #
    # @param command [String] the show command to execute
    # @param type [:ascii, :structured] ASCII or structured output.
    #             Default is :ascii
    # @return [String] the output of the show command, if type == :ascii
    # @return [Hash{String=>String}] key-value pairs, if type == :structured
    def show(command, type=:ascii)
      super
      if type == :ascii
        return req('cli_show_ascii', command)
      elsif type == :structured
        return req('cli_show', command)
      else
        fail TypeError
      end
    end

    # Sends a request to the NX API and returns the body of the request or
    # handles errors that happen.
    # @raise ConnectionRefused if NXAPI is disabled
    # @raise HTTPUnauthorized if username/password are invalid
    # @raise HTTPBadRequest (should never occur)
    # @raise RequestNotSupported
    # @raise CliError if any command is rejected as invalid
    #
    # @param type ["cli_show", "cli_show_ascii"] Specifies the type of command
    #             to be executed.
    # @param command_or_list [String, Array<String>] The command or array of
    #                        commands which should be run.
    # @return [Hash, Array<Hash>] output when type == "cli_show"
    # @return [String, Array<String>] output when type == "cli_show_ascii"
    def req(type, command_or_list)
      if command_or_list.is_a?(Array)
        # NXAPI wants config lines to be separated by ' ; '
        command = command_or_list.join(' ; ')
      else
        command = command_or_list
        command_or_list = [command]
      end

      debug("Input (#{type}): \'#{command}\'")
      if cache_enable? && @cache_hash[type] && @cache_hash[type][command]
        return @cache_hash[type][command]
      end

      # form the request
      request = build_http_request(type, command)

      # send the request and get the response
      debug("Sending HTTP request to NX-API at #{@http.address}:\n" \
            "#{request.to_hash}\n#{request.body}")
      begin
        response = @http.request(request)
      rescue Errno::ECONNREFUSED, Errno::ECONNRESET
        emsg = 'Connection refused or reset. Is the NX-API feature enabled?'
        raise Cisco::Client::ConnectionRefused, emsg
      end
      handle_http_response(response)
      output = parse_response(response)

      prev_cmds = []
      if output.is_a?(Array)
        output.zip(command_or_list) do |o, cmd|
          handle_output(prev_cmds, cmd, o)
          prev_cmds << cmd
        end
        output = output.each { |o| o['body'] }
      else
        handle_output(prev_cmds, command, output)
        output = output['body']
      end

      output = '' if type == 'cli_show_ascii' && output.empty?

      @cache_hash[type][command] = output if cache_enable?
      output
    end
    private :req

    def build_http_request(type, command_string)
      if @username.nil? || @password.nil?
        request = Net::HTTP::Post.new(NXAPI_UDS_URI_PATH)
        request['Cookie'] = 'nxapi_auth=admin:local'
      else
        request = Net::HTTP::Post.new(NXAPI_REMOTE_URI_PATH)
        request.basic_auth("#{@username}", "#{@password}")
      end
      request.content_type = 'application/json'
      request.body = {
        'ins_api' => {
          'version'       => NXAPI_VERSION,
          'type'          => "#{type}",
          'chunk'         => '0',
          'sid'           => '1',
          'input'         => "#{command_string}",
          'output_format' => 'json',
        }
      }.to_json
      request
    end
    private :build_http_request

    def handle_http_response(response)
      debug("HTTP Response: #{response.message}\n#{response.body}")
      case response
      when Net::HTTPUnauthorized
        emsg = 'HTTP 401 Unauthorized. Are your NX-API credentials correct?'
        fail HTTPUnauthorized, emsg
      when Net::HTTPBadRequest
        emsg = "HTTP 400 Bad Request\n#{response.body}"
        fail HTTPBadRequest, emsg
      end
    end
    private :handle_http_response

    def parse_response(response)
      body = JSON.parse(response.body)

      # In case of an error the JSON may not be complete, so we need to
      # proceed carefully, as blindly doing body["ins_api"]["outputs"]["output"]
      # could throw an error otherwise.
      output = body['ins_api']
      if output.nil?
        fail Cisco::Client::ClientError, "unexpected JSON output:\n#{body}"
      end
      output = output['outputs'] if output['outputs']
      output = output['output'] if output['output']

      output
    rescue JSON::ParserError
      raise Cisco::Client::ClientError, "response is not JSON:\n#{body}"
    end
    private :parse_response

    def handle_output(prev_cmds, command, output)
      if output['code'] == '400'
        # CLI error.
        # Examples: "Invalid input", "Incomplete command", etc.
        fail CliError.new(command, output['msg'], output['code'],
                          output['clierror'], prev_cmds)
      elsif output['code'] == '413'
        # Request too large
        fail Cisco::Client::RequestNotSupported, "Error 413: #{output['msg']}"
      elsif output['code'] == '501'
        # if structured output is not supported for this command,
        # raise an exception so that the calling function can
        # handle accordingly
        fail Cisco::Client::RequestNotSupported, \
             "Structured output not supported for #{command}"
      else
        debug("Result for '#{command}': #{output['msg']}")
        if output['body'] && !output['body'].empty?
          debug("Output: #{output['body']}")
        end
      end
    end
    private :handle_output
  end
end
