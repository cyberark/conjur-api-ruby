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

module Conjur
  module BuildObject
    def self.included base
      base.module_eval do
        extend ClassMethods
      end
    end

    module ClassMethods
      def build_object id, credentials, default_class:
        id = Id.new id
        class_name = id.kind.classify.to_sym
        find_class(class_name, default_class)
          .new(id, credentials)
      end

      def find_class class_name, default_class
        cls = if Conjur.constants.member?(class_name)
          Conjur.const_get(class_name)
        else
          default_class
        end
        cls < BaseObject ? cls : default_class
      end
    end

    def build_object id, default_class: Resource
      self.class.build_object id, credentials, default_class: default_class
    end
  end
end
