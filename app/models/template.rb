class Template
  include MongoMapper::Document

  key :label, String
  key :description, String
  key :position, Integer

  many :datum_templates, :order => 'position asc'

  before_save :sort_datum_templates

  validates_presence_of :label
  validates_uniqueness_of :label, :case_sensitive => false

protected

  def sort_datum_templates
    self.datum_templates.sort_by!(&:position)
  end

end