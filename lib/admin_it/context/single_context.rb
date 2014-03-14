require File.join %w(extend_it dsl)
require File.join %w(extend_it symbolize)

using ExtendIt::Symbolize

module AdminIt
  class Section
    extend ExtendIt::Dsl
    include Renderable
    dsl_accessor :name, :display_name
    dsl_boolean :visible
    # dsl_block :render_context
    def fields(*names)
      names.empty? ? @fields ||= [] : @fields = names
    end
  end

  module Identifiable
    def self.included(base)
      base.extend(ClassMethods)
    end

    def identity; end

    protected

    def context_param
      identity.nil? ? super : "#{super}(#{identity})"
    end

    module ClassMethods
    end
  end

  class SingleContext < Context
    class << self
      dsl_block :entity_getter, :entity_saver, :entity_destroyer
    end

    def self.sections
      (@sections ||= {}).values
    end

    def self.section(*names, &block)
      @sections ||= {}
      names.ensure_symbols.each do |name|
        if @sections.key?(name)
          section = @sections[name]
        else
          if @sections.empty?
            general = Section.new
            general.name(:general)
            # TODO: require this and other files after I18n config in engine.rb
            #general.display_name(I18n.t('admin_it.collection.no_data'))
            general.display_name('Основные свойства')
            general.fields(*fields.map(&:field_name))
            @sections[:general] = general
          end
          section = Section.new
          section.name(name)
          @sections[name] = section
        end
        section.instance_eval(&block) if block_given?
      end
    end

    def self.single?
      true
    end

    def self.path(entity)
      AdminIt::Engine.routes.url_helpers.send(
        "#{resource.name}_path",
        entity
      )
    end

    class_attr_reader :entity_getter, :entity_saver, :entity_destroyer, :sections
    attr_accessor :entity

    after_load do |store: {}, params: {}|
      self.section = params[:section] || store[:section]
    end

    before_save do |params: {}|
      params.merge!(section: section)
    end

    def values
      return {} if @entity.nil?
      Hash[fields(scope: :readable).map { |f| [f.name, f.read(@entity)] }]
    end

    def path(_entity: nil)
      _entity ||= entity
      self.class.path(_entity)
    end

    def section
      @section ||= sections.empty? ? :none : :general
    end

    def section=(value)
      value = value.downcase.to_sym if value.is_a?(String)
      return unless value.is_a?(Symbol)
      if sections.empty?
        return if section != :none
      else
        return unless sections.map(&:name).include?(value)
      end
      @section = section
    end

    protected

    def load_context
      self.entity =
        if entity_getter.nil?
          getter = "#{resource.name}_#{name}_entity".to_sym
          if controller.respond_to?(getter)
            controller.send(getter)
          else
            getter = "#{name}_entity"
            if controller.respond_to?(getter)
              controller.send(getter, entity_class)
            else
              load_entity
            end
          end
        else
          entity_getter.call(controller.params)
        end
    end

    def load_entity(identity: nil)
      []
    end
  end

  class SavableSingleContext < SingleContext
    def self.save_action; end

    def save_entity
      if entity_saver.nil?
        if controller.respond_to?("#{resource.name}_save")
          controller.send("#{resource.name}_save", name)
        elsif controller.respond_to?(:save)
          controller.save(entity_class, name)
        else
          do_save_entity
        end
      else
        entity_saver.call(controller, name)
      end
    end

    class_attr_reader :save_action

    protected

    def do_save_entity; end
  end

  class EditContext < SavableSingleContext
    include Identifiable

    def self.path(entity)
      AdminIt::Engine.routes.url_helpers.send(
        "edit_#{resource.name}_path", entity
      )
    end

    def self.save_action
      :update
    end

    def self.entity_path?
      true
    end

    class << self
      protected

      def default_icon
        'pencil'
      end
    end
  end

  class NewContext < SavableSingleContext
    def self.path
      AdminIt::Engine.routes.url_helpers.send("new_#{resource.name}_path")
    end

    def self.save_action
      :create
    end
  end
end
