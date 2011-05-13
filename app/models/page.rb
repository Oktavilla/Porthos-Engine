class Page
  include MongoMapper::Document
  plugin MongoMapper::Plugins::MultiParameterAttributes

  taggable

  key :position, Integer
  key :title, String
  key :uri, String
  key :layout_class, String
  key :active, Boolean
  key :restricted, Boolean
  key :published_on, Time
  timestamps!

  ensure_index :created_at
  ensure_index :updated_at

  belongs_to :created_by, :class_name => 'User'
  belongs_to :updated_by, :class_name => 'User'
  belongs_to :field_set

  many :data, :order => 'position asc' do
    def [](handle)
      detect { |d| d.handle == handle.to_s }
    end
  end

  validates_presence_of :title

  before_save :sort_data

  class << self
    def from_template(template)
      self.new.tap do |page|
        page.data = template.datum_templates.map do |datum_template|
          Datum.from_template(datum_template)
        end
      end
    end
  end

  # TODO: Test me
  def data_attributes=(datum_array)
    self.data = datum_array.map do |i, datum_attrs|
      datum_attrs.to_options!
      if id = datum_attrs.delete(:id)
        unless datum_attrs[:_destroy]
          data.detect { |d| d.id.to_s == id }.tap do |datum|
            datum.update_attributes(datum_attrs) if datum_attrs.keys.any?
          end
        end
      else
        Datum.new(datum_attrs)
      end
    end.compact
  end

  def fields
    field_set.fields
  end

  def node
    Node.where(:resource_type => 'Page', :resource_id => self.id)
  end

  def node=(node_attributes)
    node ? node.attributes.merge(node_attributes) : Node.new(node_attributes)
  end

  def index_node
    field_set.node
  end


  delegate :template,
           :to => :field_set

  def custom_association_contexts
    CustomAssociation.where(:parent => self)
  end

  scope :unpublished, lambda {
    where(:$or => [{:published_on => nil}, {:published_on.gt => Time.now}])
  }

  scope :published, lambda {
    where(:published_on.lt => Time.now)
  }

  scope :published_within, lambda { |from, to|
    where(:published_on.gt > from, :published_on.lt => to)
  }

  scope :include_restricted, lambda { |restricted|
    where(:$or => [{:restricted => restricted}, { :restricted => false}])
  }

  scope :created_latest, sort(:created_at.desc)

  scope :updated_latest, where(:updated_at.gt => :created_at).sort(:updated_at.desc)

  scope :with_field_set, lambda { |field_set_id|
    where(:field_set_id => field_set_id)
  }

  scope :created_by, lambda { |user_id|
    where(:created_by_id => user_id)
  }

  scope :updated_by, lambda { |user_id|
    where(:updated_by_id => user_id)
  }

  scope :order_by, lambda { |order_by|
    sort(order_by)
  }

  scope :is_published, lambda { |is_published|
    if is_published
      where(:published_on.lt => Time.now)
    else
      where(:$or => [{:published_on => nil}, {:published_on.lt => Time.now}])
    end
  }

#  scope :with_custom_attributes_field, lambda { |ca_field|
#    joins("left join custom_attributes as #{ca_field} on #{ca_field}.context_type = 'Page' and #{ca_field}.context_id = pages.id and #{ca_field}.handle = '#{ca_field}'")
#  }

  before_create :set_created_by
  before_save   :generate_uri
  before_update :set_updated_by

  #after_initialize :create_namespaced_tagging_methods
  # after_save :commit_to_sunspot

  def contents_as_text
    contents.select{|c| c.active? }.collect do |content|
      def render_content(content_resource)
        if content_resource.is_a?(ContentImage) or content_resource.is_a?(ContentVideo)
          "#{content_resource.asset.title} #{content_resource.asset.description}"
        elsif content_resource.is_a?(ContentTextfield)
          content_resource.body
        elsif content_resource.is_a?(ContentTeaser)
          "#{content_resource.title} #{content_resource.body}"
        end
      end
      if !content.restricted? && !content.module?
        if content.collection?
          content.contents.collect {|c| render_content(c)}
        else
          render_content(content.resource)
        end
      end
    end.join(' ').gsub(/<\/?[^>]*>/, "")
  end

  def published_on_parts
    @published_on_parts ||= {
      :year => published_on.strftime("%Y"),
      :month => published_on.strftime("%m"),
      :day => published_on.strftime("%d")
    }
  end

  def published?
    published_on.present? && published_on <= DateTime.now
  end

  def full_uri
    # @full_uri ||= node ? node.url : (index_node ? [index_node.url, to_param].join('/') : uri)
  end

  def category
    @category ||= field_set.allow_categories? ? Page.tags_by_count(:namespace => field_set.handle).first : nil
  end

  def category_name
    @category_name ||= category ? category.name : ''
  end

  def category_method_name
    @category_method_name ||= "#{field_set.handle}_tag_names"
  end

  def can_have_a_node?
    published_on.present? && field_set.allow_node_placements? && node.blank?
  end

  def in_restricted_context?
    @in_restricted_context ||= restricted? || node_restricted? || index_node_restricted?
  end

protected

  def create_reader_for_datum(datum)
    self.class.send :attr_reader, datum.handle
    instance_variable_set("@#{datum.handle}".to_sym, datum.value)
  end

  def node_restricted?
    node && (node.restricted? || node.ancestors.detect { |n| n.restricted? })
  end

  def index_node_restricted?
    index_node && (index_node.restricted? || index_node.ancestors.detect { |n| n.restricted? })
  end

  # def method_missing_with_find_custom_associations(method, *args)
  #   # Check that we dont match any other method_missing hacks before we start query the database
  #   begin
  #     method_missing_without_find_custom_associations(method, *args)
  #   rescue
  #     if args.size == 0
  #       handle = method.to_s.gsub(/\?/, '')
  #       if field = fields.detect { |field| field.is_a?(AssociationField) && field.handle == handle }
  #         match = field.target_handle.blank? ? custom_associations_by_handle(handle) : custom_association_contexts_by_handle(field.target_handle)
  #         if match.any?
  #           unless field.target_handle.present?
  #             match.first.relationship == 'one_to_one' ? match.first.target : Porthos::CustomAssociationProxy.new({
  #               :target_class => match.first.target_type.constantize,
  #               :target_ids   => match.collect { |m| m.target_id }
  #             })
  #           else
  #             field.relationship == 'one_to_one' ? match.first.context : Porthos::CustomAssociationProxy.new({
  #               :target_class => match.first.context_type.constantize,
  #               :target_ids   => match.collect { |m| m.context_id }
  #             })
  #           end
  #         # Do we have a matching field but no records, return nil for
  #         # page.handle ? do stuff in the views
  #         else
  #           nil
  #         end
  #       else
  #         # no match raise method missing again
  #         method_missing_without_find_custom_associations(method, *args)
  #       end
  #     else
  #       method_missing_without_find_custom_associations(method, *args)
  #     end
  #   end
  # end
  # alias_method_chain :method_missing, :find_custom_associations

private

  def sort_data
    self.data.sort_by!(&:position)
  end

  def generate_uri
    self.uri = title.parameterize unless uri.present?
  end

  def set_created_by
    self.created_by = User.current
  end

  def set_updated_by
    self.updated_by = User.current
  end

  # def commit_to_sunspot
  #   Delayed::Job.enqueue SunspotIndexJob.new('Page', self.id)
  # end

end