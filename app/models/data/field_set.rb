class FieldSet < Datum
  key :template_name, String
  key :content_template_id, ObjectId
  many :data do
    def [](handle)
      detect { |d| d.handle == handle.to_s }
    end
  end

  def data_attributes=(_data)
    _data = _data.values if _data.kind_of?(Hash)
    _data.each do |attrs|
      attrs.to_options!
      datum_id = attrs.delete(:id)
      data.detect { |d| d.id.to_s == datum_id.to_s }.tap do |datum|
        datum.attributes = attrs if datum && attrs.keys.any?
      end if datum_id
    end
  end

  def template
    @template ||= template_name.present? ? FieldSetFileTemplate.new(template_name) : FieldSetFileTemplate.default
  end

  class << self
    def from_template(datum_template)
      content_template = datum_template.is_a?(FieldSetTemplate) ? datum_template.content_template : datum_template
      content_template.to_datum.tap do |field_set|
        unless datum_template == content_template
          datum_template.shared_attributes.each do |k, v|
            field_set[k] = v
          end
        end
      end
    end
  end
end
