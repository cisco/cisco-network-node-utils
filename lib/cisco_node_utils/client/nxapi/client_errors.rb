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

require_relative '../client_errors'

# Namespace for all NXAPI-related functionality and classes.
class Cisco::Client::NXAPI < Cisco::Client
  # CliError indicates that the node rejected the CLI as invalid.
  class CliError < Cisco::Client::RequestFailed
    attr_reader :clierror, :msg, :code
    def initialize(input, msg, code, clierror, previous)
      super("#{msg}\n#{clierror}", input, previous)
      @clierror = clierror
      @msg = msg
      @code = code
    end
  end

  # HTTPBadRequest means we did something wrong in our request
  class HTTPBadRequest < Cisco::Client::ClientError
  end

  # HTTPUnauthorized means we provided incorrect credentials
  class HTTPUnauthorized < Cisco::Client::AuthenticationFailed
  end
end
