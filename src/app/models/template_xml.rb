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
    @errors = []
    @xml = Nokogiri::XML(xmlstr) { |config| config.strict }
    @relax_file = "#{::Rails.root.to_s}/app/util/template-rng.xml"
  end

  def validate
    xsd = Nokogiri::XML::RelaxNG(File.read(@relax_file))
    errors = xsd.validate(@xml).map {|err| err.message}
    if errors.any?
      @errors << I18n.t('template_xml.errors.invalid_xml')
      @errors += errors
    end
    @errors << I18n.t('template_xml.errors.name_is_not_set') if @xml.xpath('/template/name').text.empty?
    @errors
  end

  def self.validate(xmlstr)
    begin
      doc = TemplateXML.new(xmlstr)
    rescue Nokogiri::XML::SyntaxError
      return [I18n.t('template_xml.errors.xml_parse_error')]
    end
    return doc.validate
  end

  def name=(name)
    if @xml.root.nil? || @xml.root.name != 'template'
      @xml.root = @xml.create_element('template')
    end

    if @xml.xpath('/template/name').empty?
      @xml.xpath('/template').first << @xml.create_element('name')
    end

    @xml.xpath('/template/name').first.content = name unless name.blank?
  end

  def name
    doc.xpath('/template/name').text
  end

  def to_xml
    @xml.to_xml
  end
end
