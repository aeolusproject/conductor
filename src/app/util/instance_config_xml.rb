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

class InstanceConfigXML
  class ValidationError < RuntimeError; end

  def initialize(xmlstr = "")
    doc = Nokogiri::XML(xmlstr)
    @root = doc.root.at_xpath('/instance-config') if doc.root
  end

  def to_s
    @root.to_s
  end

  def validate!
    errors = []
    errors << "No instance uuid found" unless uuid
    raise ValidationError, errors.join(", ") unless errors.empty?
  end

  def uuid
    @root['id'] if @root
  end

  def to_s
    @root.to_s
  end
end
