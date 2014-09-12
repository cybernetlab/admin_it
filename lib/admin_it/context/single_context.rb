#
module AdminIt
  using EnsureIt if EnsureIt.refined?

  #
  class Section
    extend ExtendIt::Base
    include ExtendIt::Dsl
    include Renderable
    include Iconed

    attr_reader :name, :display_name, :fields

    dsl do
      dsl_accessor :name, :display_name
      dsl_boolean :visible

      def use_fields(*names, except: nil)
        names = names.ensure_array(:flatten, :ensure_symbol, :compact, :uniq)
        except = except.ensure_array(:flatten, :ensure_symbol, :compact, :uniq)
        fields =
          if names.empty?
            dsl_get(:fields, default: [])
          else
            context = dsl_get(:context, default: nil)
            names & context.fields.map(&:field_name)
          end
        fields -= except
        dsl_set(:fields, fields)
      end
    end

    def visible?
      @visible.nil? ? @visible = true : @visible == true
    end

    def initialize(name, context, display_name: nil)
      @name = name
      @display_name = display_name || name
      @context = context
      @fields = context.fields.map(&:field_name)
      context.sections.each do |section|
        next if section.name == name
        @fields -= section.fields
      end
    end
  end

  #
  module Identifiable
    def self.included(base)
      base.extend(ClassMethods)
    end

    def identity; end

    def to_link
      identity.nil? ? super : "#{super}(#{identity})"
    end

    protected

    #
    module ClassMethods
    end
  end

  #
  class SingleContext < Context
    dsl do
      dsl_block :entity_getter, :entity_saver, :entity_destroyer
      dsl_accessor :show_resource_link

      dsl_hash_of_objects :sections, single: :section do |name, **opts|
        if @sections.empty?
          # TODO: require this and other files after I18n config in engine.rb
          # general.display_name(I18n.t('admin_it.collection.no_data'))
          general = Section.new(
            :general,
            self,
            display_name: 'Основные свойства'
          )
          @sections[:general] = general
        end
        name == :general ? @sections[:general] : Section.new(name, self)
      end
    end

    #def self.before_configure()
    #  @show_resource_link = true
    #end

    def self.sections
      (@sections ||= {}).values
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

    class_attr_reader :entity_getter, :entity_saver, :entity_destroyer,
                      :sections, :show_resource_link
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
      value = value.ensure_symbol(downcase: true) || return
#      if s.empty?
#        return if section != :none
#      else
#        return unless s.map(&:name).include?(value.to_s)
#      end
      @section = value
    end

    def url_params(**params)
      params[:section] = section unless params.key?(:section)
      super(**params)
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

  #
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

  #
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

  #
  class NewContext < SavableSingleContext
    def self.path
      AdminIt::Engine.routes.url_helpers.send("new_#{resource.name}_path")
    end

    def path(_entity: nil)
      self.class.path
    end

    def self.save_action
      :create
    end
  end
end
