#
#   Copyright 2011 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
module Aeolus
  module Conductor
    module API
      class Error < StandardError
        attr_reader :status
        attr_reader :message

        def initialize(status, message = nil)
          @status = status
          @message  = message
        end
      end

      class BuildDeleteFailure < Error; end
      class BuildNotFound < Error; end
      class ImageDeleteFailure < Error; end
      class ImageNotFound < Error; end
      class InsufficientParametersSupplied < Error; end
      class ParameterDataIncorrect < Error; end
      class PermissionDenied < Error; end
      class PushError < Error; end
      class ProviderAccountNotFound < Error; end
      class ProviderImageDeleteFailure < Error; end
      class ProviderImageNotFound < Error; end
      class ProviderImageStatusNotFound < Error; end
      class TargetImageDeleteFailure < Error; end
      class TargetImageNotFound < Error; end
      class TargetImageStatusNotFound < Error; end
      class TargetNotFound < Error; end
    end

    module Base
      class ImageNotFound < StandardError; end
      class BlankImageId < StandardError; end
    end
  end
end
