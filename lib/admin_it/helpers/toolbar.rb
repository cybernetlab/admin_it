module AdminIt
  #
  module Helpers
    #
    class ToolbarItem < WrapIt::Link
      attr_accessor :icon, :add_class, :add_data
      option :icon
      option :add_class
      option :add_data
      section :icon
      place :icon, before: :body

      before_capture do
        unless icon.nil?
          self[:icon] << html_safe("<i class=\"fa fa-#{icon}\"></i> ")
        end
        html_class << add_class
        html_data.merge!(add_data) if add_data.is_a?(Hash)
#        options = { tag: 'li' }
#        options[:class] = 'active' if resource == @template.resource
#        wrap(options)
      end
    end

    #
    class ToolbarButtons < WrapIt::Container
      html_class 'btn-group'
      child :button, ToolbarItem, class: 'btn navbar-btn'
    end

    #
    class Toolbar < WrapIt::Container
      default_tag 'nav'
      html_class 'navbar'
      child :item, ToolbarItem
      child :button, ToolbarItem, class: 'btn navbar-btn'
      child :buttons, ToolbarButtons

      after_initialize { self.deffered_render = true }
    end

    register :toolbar, Toolbar
  end
end
