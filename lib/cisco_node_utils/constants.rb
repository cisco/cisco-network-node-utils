# January 2016, Glenn F. Matthews
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

# Shared constants for the Cisco module
module Cisco
  PLATFORMS = [
    # Cisco IOS XR
    :ios_xr,
    # Cisco NX-OS (Nexus switches)
    :nexus,
  ]

  DATA_FORMATS = [
    # Cisco CLI. Indentation is significant.
    :cli,
    # Structured data format specific to NX-API
    :nxapi_structured,
    # YANG JSON
    :yang_json,
  ]

  YANG_SET_MODE = [
    :merge_config,
    :replace_config,
    :delete_config,
  ]
end
