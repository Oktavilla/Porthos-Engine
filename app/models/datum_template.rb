class DatumTemplate
  include MongoMapper::EmbeddedDocument
  include Porthos::DatumMethods

  validates_presence_of :label

  after_destroy :propagate_removal

  def destroy
    run_callbacks(:destroy) { delete }
  end

  def delete
    _root_document.pull(:datum_templates => { :_id => self.id })
  end

  class << self
    def from_type(type, attributes = {})
      case type
      when "FieldTemplate"
        if attributes['input_type'] == 'string'
          StringFieldTemplate.new(attributes)
        else
          FieldTemplate.new(attributes)
        end
      else
        type.constantize.new(attributes)
      end
    end

    def propagate_changes_job(find_query, updates)
      Page.collection.update(find_query, updates, :multi => true)
    end
  end

  def to_datum
    datum_class.constantize.from_template(self)
  end

  def datum_class
    (self.class.ancestors - self.class.included_modules).collect do |klass|
      klass.to_s.gsub('Template', '')
    end.detect do |klass_name|
      begin
        defined?(klass_name.constantize)
      rescue NameError
        false
      end
    end
  end

  def shared_attributes
    attributes.clone.except(:_id, :_type).inject({}) do |hash, entry|
      key, value = entry
      hash[key] = value.duplicable? ? value.clone : value
      hash
    end
  end

private

  def propagate_self
    [{
      'page_template_id' => self._root_document.id
    }, {
      '$addToSet' => {
        'data' => self.to_datum.to_mongo
      }
    }].tap do |_payload|
      Rails.env.production? ? DatumTemplate.delay.propagate_changes_job(*_payload) : DatumTemplate.propagate_changes_job(*_payload)
    end
  end

  def propagate_changes
    query_handle = if respond_to?(:handle_changed?)
      handle_changed? ? handle_was : handle
    else
      handle
    end

    [{
      'page_template_id' => self._root_document.id,
      'data.handle' => query_handle,
    }, {
      '$set' => shared_attributes.inject({}) { |hash, (k, v)| hash.merge({ "data.$.#{k}" => v }) }
    }].tap do |_payload|
      Rails.env.production? ? DatumTemplate.delay.propagate_changes_job(*_payload) : DatumTemplate.propagate_changes_job(*_payload)
    end
  end

  def propagate_removal
    [{
      'page_template_id' => self._root_document.id
    }, {
      '$pull' => {
        'data' => { 'handle' => self.handle }
      }
    }].tap do |_payload|
      Rails.env.production? ? DatumTemplate.delay.propagate_changes_job(*_payload) : DatumTemplate.propagate_changes_job(*_payload)
    end
  end

end
