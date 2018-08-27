# frozen_string_literal: true

# Copyright 2013-2018 CyberArk Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'conjur/cast'

module Conjur
  class BaseObject
    include Cast
    include QueryString
    include LogSource
    include BuildObject
    include Routing
    
    attr_reader :id, :credentials
    
    def initialize id, credentials
      @id = cast_to_id(id)
      @credentials = credentials
    end

    def as_json options={}
      {
        id: id.to_s
      }
    end

    def account; id.account; end
    def kind; id.kind; end
    def identifier; id.identifier; end
    
    def username
      credentials[:username] or raise "No username found in credentials"
    end
  end
end
