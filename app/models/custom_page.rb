class CustomPage < Item
  key :template_name, String

  tankit Porthos.config.tanking.index_name do
    indexes :title
    indexes :uri
    indexes :tag_names
    indexes :data
  end

  acts_as_uri :title,
              :target => :uri,
              :only_when_blank => true

  class << self
    def from_template(template = nil, *args)
      self.new(*args)
    end
  end

  def can_have_a_node?
    published? && node.blank?
  end

  def page_template
    nil
  end

  def template
    @template ||= template_name.present? ? PageFileTemplate.new(template_name) : PageFileTemplate.default
  end

end
