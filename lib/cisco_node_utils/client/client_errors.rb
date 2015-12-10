#!/usr/bin/env ruby
#
# October 2015, Glenn F. Matthews
#
# Copyright (c) 2015 Cisco and/or its affiliates.
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

class Cisco::Client
  # Base class for client errors
  class ClientError < RuntimeError
  end

  # ConnectionRefused means the server isn't listening
  class ConnectionRefused < ClientError
  end

  # AuthenticationFailed means we were able to connect but not login
  class AuthenticationFailed < ClientError
  end

  # RequestNotSupported means we made a request that was validly
  # constructed but includes options that are unsupported.
  #
  # An example would be requesting structured output on a CLI command
  # that only supports ASCII output.
  class RequestNotSupported < ClientError
  end

  # RequestFailed means the request was validly constructed but the
  # requested operation did not execute successfully.
  #
  # rejected_input is the command(s) that failed
  # successful_input is any command(s) that succeeded despite the failure
  class RequestFailed < ClientError
    attr_reader :rejected_input, :successful_input
    def initialize(msg, rejected_input, successful_input=[])
      super(msg)
      @rejected_input = rejected_input
      @successful_input = successful_input
    end

    def to_s
      s = ''
      if rejected_input.is_a?(Array)
        if rejected_input.length > 1
          s += "The following commands were rejected:\n"
          s += "  #{rejected_input.join("\n  ")}\n"
        else
          s += "The command '#{rejected_input.first}' was rejected "
        end
      else
        s += "The command '#{rejected_input}' was rejected "
      end
      s += "with error:\n#{super}"
      s
    end
  end
end
