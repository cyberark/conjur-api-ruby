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

require 'conjur/escape'

module Conjur
  # Encapsulates a Conjur id, which consists of account, kind, and identifier.
  class Id
    include Conjur::Escape

    attr_reader :id

    def initialize id
      @id = id
    end

    # The organization account, obtained from the first component of the id.
    def account; id.split(':', 3)[0]; end
    # The object kind, obtained from the second component of the id.
    def kind; id.split(':', 3)[1]; end
    # The object identifier, obtained from the third component of the id. The
    # identifier must be unique within the `account` and `kind`.
    def identifier; id.split(':', 3)[2]; end
    
    # Defines id equivalence using the string representation.
    def == other
      if other.is_a?(String)
        to_s == other
      else
        super
      end
    end

    # @return [String] the id string.
    def as_json options={}
      @id
    end

    # Splits the id into 3 components, and then joins them with a forward-slash `/`.
    def to_url_path
      id.split(':', 3)
        .map(&method(:path_escape))
        .join('/')
    end
    
    # @return [String] the id string
    def to_s
      id
    end
  end
end
