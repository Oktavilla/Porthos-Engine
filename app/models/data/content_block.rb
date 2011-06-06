class ContentBlock < Datum
  key :allow_images, Boolean, :default => lambda { false }
  key :allow_pages, Boolean, :default => lambda { false }
  key :allow_texts, Boolean, :default => lambda { false }
  key :content_templates_ids, Array, :typecast => 'ObjectId'

  many :content_templates, :in => :content_templates_ids
  many :data do
    def active
      find_all { |d| d.active? }
    end
  end

  before_save :sort_data

  def pages
    @pages ||= data.active.find_all { |d| d.is_a?(PageAssociation) }.collect { |d| d.page }
  end

  def images
    @images ||= data.active.find_all { |d| d.is_a?(Image) }
  end

  def texts
    @texts ||= data.active.find_all { |d| d.is_a?(StringField) }
  end

protected

  def sort_data
    self.data.sort_by!(&:position)
  end

end