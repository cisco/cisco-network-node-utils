# NXAPI client library.
#
# November 2014, Glenn F. Matthews
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

require_relative '../client'
require 'json'
require 'net/http'

include Cisco::Logger

# Class representing an HTTP client connecting to a NXAPI server.
class Cisco::Client::NXAPI < Cisco::Client
  # Location of unix domain socket for NXAPI localhost
  NXAPI_UDS = '/tmp/nginx_local/nginx_1_be_nxapi.sock'
  # NXAPI listens for remote connections to "http://<switch IP>/ins"
  # NXAPI listens for local connections to "http://<UDS>/ins_local"
  NXAPI_REMOTE_URI_PATH = '/ins'
  NXAPI_UDS_URI_PATH = '/ins_local'
  # Latest supported version is 1.0
  NXAPI_VERSION = '1.0'

  register_client(self)

  # Constructor for Client. By default this connects to the local
  # unix domain socket. If you need to connect to a remote device,
  # you must provide the host/username/password parameters.
  def initialize(**kwargs)
    # rubocop:disable Style/HashSyntax
    super(data_formats: [:nxapi_structured, :cli],
          platform:     :nexus,
          **kwargs)
    # rubocop:enable Style/HashSyntax
    # Default: connect to unix domain socket on localhost, if available
    if @host.nil?
      unless File.socket?(NXAPI_UDS)
        fail Cisco::ConnectionRefused, \
             "No host specified but no UDS found at #{NXAPI_UDS} either"
      end
      # net_http_unix provides NetX::HTTPUnix, a small subclass of Net::HTTP
      # which supports connection to local unix domain sockets. We need this
      # in order to run natively under NX-OS but it's not needed for off-box
      # unit testing where the base Net::HTTP will meet our needs.
      require 'net_http_unix'
      @http = NetX::HTTPUnix.new('unix://' + NXAPI_UDS)
      @cookie = kwargs[:cookie]
    else
      # Remote connection. This is primarily expected
      # when running e.g. from a Unix server as part of Minitest.
      @http = Net::HTTP.new(@host)
    end
    # The default read time out is 60 seconds, which may be too short for
    # scaled configuration to apply. Change it to 300 seconds, which is
    # also used as the default config by firefox.
    @http.read_timeout = 300
    @address = @http.address

    # Make sure we can actually connect to the socket
    get(command: 'show hostname')
  end

  def self.validate_args(**kwargs)
    super
    if kwargs[:host].nil?
      # Connection to UDS - no username or password either
      fail ArgumentError unless kwargs[:username].nil? && kwargs[:password].nil?
      validate_cookie(**kwargs)
    else
      # Connection to remote system - username and password are required
      fail TypeError, 'username is required' if kwargs[:username].nil?
      fail TypeError, 'password is required' if kwargs[:password].nil?
    end
  end

  def self.validate_cookie(**kwargs)
    return if kwargs[:cookie].nil?
    format = 'Cookie format must match: <username>:local'
    msg = "Invalid cookie: [#{kwargs[:cookie]}]. : #{format}"

    fail TypeError, msg unless kwargs[:cookie].is_a?(String)
    fail TypeError, msg unless /\S+:local/.match(kwargs[:cookie])
    fail ArgumentError, 'empty cookie' if kwargs[:cookie].empty?
  end

  # Clear the cache of CLI output results.
  #
  # If cache_auto is true (default) then this will be performed automatically
  # whenever a set() is called, but providers may also call this
  # to explicitly force the cache to be cleared.
  def cache_flush
    @cache_hash = {
      'cli_conf'       => {},
      'cli_show'       => {},
      'cli_show_ascii' => {},
    }
  end

  # Configure the given CLI command(s) on the device.
  #
  # @raise [RequestNotSupported] if this client doesn't support CLI config
  #
  # @param data_format one of Cisco::DATA_FORMATS. Default is :cli
  # @param context [String, Array<String>] Zero or more configuration commands
  #   used to enter the desired CLI sub-mode
  # @param values [String, Array<String>] One or more commands
  #   to enter within the CLI sub-mode.
  # @param kwargs data-format-specific args
  def set(data_format: :cli,
          context: nil,
          values: nil,
          **_kwargs)
    # we don't currently support nxapi_structured for configuration
    fail Cisco::RequestNotSupported if data_format == :nxapi_structured
    context = munge_to_array(context)
    values = munge_to_array(values)
    super
    req('cli_conf', context + values)
  end

  # Get the given state from the device.
  #
  # Unlike set() this will not clear the CLI cache;
  # multiple calls with the same parameters may return cached data
  # rather than querying the device repeatedly.
  #
  # @raise [Cisco::RequestNotSupported] if
  #   structured output is requested but the given command can't provide it.
  # @raise [Cisco::CliError] if the command is rejected by the device
  #
  # @param data_format one of Cisco::DATA_FORMATS. Default is :cli
  # @param command [String] the show command to execute
  # @param context [String, Array<String>] Context to refine the results
  # @param value [String] Specific key to look up
  # @param kwargs data-format-specific args
  # @return [String, Hash]
  def get(data_format: :cli,
          command:     nil,
          context:     nil,
          value:       nil,
          **_kwargs)
    context = munge_to_array(context)
    super
    if data_format == :cli
      output = req('cli_show_ascii', command)
      return self.class.filter_cli(cli_output: output,
                                   context:    context,
                                   value:      value)
    elsif data_format == :nxapi_structured
      output = req('cli_show', command)
      return self.class.filter_data(data: output,
                                    keys: context + munge_to_array(value))
    else
      fail TypeError
    end
  end

  # Sends a request to the NX API and returns the body of the request or
  # handles errors that happen.
  # @raise Cisco::ConnectionRefused if NXAPI is disabled
  # @raise Cisco::AuthenticationFailed if username/password are invalid
  # @raise Cisco::ClientError (should never occur)
  # @raise Cisco::RequestNotSupported
  # @raise Cisco::RequestFailed if any command is rejected as invalid
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
    tries = 2
    begin
      # Explicitly use http to avoid EOFError
      # http://stackoverflow.com/a/23080693
      @http.use_ssl = false
      response = @http.request(request)
    rescue Errno::ECONNREFUSED, Errno::ECONNRESET
      emsg = 'Connection refused or reset. Is the NX-API feature enabled?'
      raise Cisco::ConnectionRefused, emsg
    rescue EOFError
      tries -= 1
      retry if tries > 0
      raise
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
      cookie = @cookie.nil? ? 'admin:local' : @cookie
      request = Net::HTTP::Post.new(NXAPI_UDS_URI_PATH)
      request['Cookie'] = "nxapi_auth=#{cookie}"
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
      fail Cisco::AuthenticationFailed, emsg
    when Net::HTTPBadRequest
      emsg = "HTTP 400 Bad Request\n#{response.body}"
      fail Cisco::ClientError, emsg
    end
  end
  private :handle_http_response

  def parse_response(response)
    body = JSON.parse(response.body)

    # In case of an error the JSON may not be complete, so we need to
    # proceed carefully, as blindly doing body["ins_api"]["outputs"]["output"]
    # could throw an error otherwise.
    output = body['ins_api']
    fail Cisco::ClientError, "unexpected JSON output:\n#{body}" if output.nil?
    output = output['outputs'] if output['outputs']
    output = output['output'] if output['output']

    output
  rescue JSON::ParserError
    raise Cisco::ClientError, "response is not JSON:\n#{response.body}"
  end
  private :parse_response

  def handle_output(prev_cmds, command, output)
    if output['code'] == '400'
      # CLI error.
      # Examples: "Invalid input", "Incomplete command", etc.
      fail Cisco::CliError.new( # rubocop:disable Style/RaiseArgs
        rejected_input:   command,
        clierror:         output['clierror'],
        msg:              output['msg'],
        code:             output['code'],
        successful_input: prev_cmds,
      )
    elsif output['code'] == '413'
      # Request too large
      fail Cisco::RequestNotSupported, "Error 413: #{output['msg']}"
    elsif output['code'] == '501'
      # if structured output is not supported for this command,
      # raise an exception so that the calling function can
      # handle accordingly
      fail Cisco::RequestNotSupported, \
           "Structured output not supported for #{command}"
    # Error 432: Requested object does not exist
    # Ignore 432 errors because it means that a property is not configured
    elsif output['code'] =~ /[45]\d\d/ && output['code'] != '432'
      fail Cisco::RequestFailed, \
           "#{output['code']} Error: #{output['msg']}"
    else
      debug("Result for '#{command}': #{output['msg']}")
      if output['body'] && !output['body'].empty?
        debug("Output: #{output['body']}")
      end
    end
  end
  private :handle_output
end
