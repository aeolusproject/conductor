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


class TemplateXML
  attr_reader :errors, :doc

  def initialize(xmlstr)
    @errors = {}
    @xml = Nokogiri::XML(xmlstr) { |config| config.strict }
    @relax_file = "#{::Rails.root.to_s}/app/util/template-rng.xml"
  end

  def validate
    xsd = Nokogiri::XML::RelaxNG(File.read(@relax_file))
    errors = xsd.validate(@xml).map {|err| err.message}
    if errors.any?
      @errors[:summary] = _("XML is not valid:")
      @errors[:failures] = errors
    end
    # TODO would be much better to validate name presence using rng template^
    if @xml.xpath('/template/name').text.empty?
      @errors[:summary] ||= _("XML is not valid:")
      @errors[:failures] ||= []
      @errors[:failures] << _("Name is not set.")
    end
    @errors
  end

  def self.validate(xmlstr)
    doc = TemplateXML.new(xmlstr)
    doc.validate[:failures].to_a
  end

  def name=(name)
    if @xml.root.nil? || @xml.root.name != 'template'
      @xml.root = @xml.create_element('template')
    end

    if @xml.xpath('/template/name').empty?
      @xml.xpath('/template').first << @xml.create_element('name')
    end

    name ||= ""
    @xml.xpath('/template/name').first.content = name
  end

  def name
    @xml.xpath('/template/name').text
  end

  def to_xml
    @xml.to_xml
  end
end
