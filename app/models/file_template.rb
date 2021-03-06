require 'enumerator'
class FileTemplate
  include Comparable

  attr_reader :name,
              :handle,
              :path,
              :full_path

  def initialize(name)
    @full_path = self.class.available_template_paths[name]
    unless @full_path
      raise "FileTemplate: #{name} is not a available template"
    end
    @path = @full_path.gsub(/(.*)app\/views\//,'')
    @handle = name
    @name = @handle.capitalize
  end

  def views
    @views ||= self.class::Views.new(self)
  end

  def <=>(other)
    self.handle <=> other.handle
  end

  def to_s
    name
  end

  class << self

    def all
      @all ||= available_template_paths.any? ? available_template_paths.collect {|name, path| self.new(name) } : []
    end

    def available_template_paths
      available_template_paths = {}
      root_directories.each do |root_path|
        if Dir.exists?(root_path)
          Dir.entries(root_path).reject { |f| f[0...1] == "." }.collect do |template_path|
            unless available_template_paths.has_key?(File.basename(template_path))
              available_template_paths[template_path] = File.join(root_path, template_path)
            end
          end
        end
      end
      available_template_paths
    end

    def default
      self.new('default')
    end

    def find(template_handle)
      self.all.detect { |template| template.handle == template_handle }
    end

    def root_path
      raise "Needs to be implemented in subclass"
    end

    def root_directories
      [File.join(Rails.root, 'app', 'views', root_path), File.join(Porthos.root, 'app', 'views', root_path)]
    end

  end

  class Views
    include Enumerable

    def initialize(template)
      @template = template
      @views = Dir.entries(@template.full_path).reject { |f| f[0...1] == "." || File.basename(f, '.*') == 'template' }
    end

    def each
      @views.each { |v| yield v }
    end

    def names
      @names ||= self.collect { |v| v.split(/\./).first.gsub(/(^\_)/, '') }
    end

    def respond_to?(*args)
      super(*args) || names.include?(args.first.to_s)
    end

    def method_missing_with_check_default(method, *args)
      _method = method.to_s
      if names.include?(_method)
        File.join(@template.path, _method)
      else
        default_template = @template.class.default
        if @template != default_template and default_template.views.respond_to?(method)
          default_template.views.send(method, *args)
        else
          method_missing_without_check_default(method, *args)
        end
      end
    end
    alias_method_chain :method_missing, :check_default
  end
end