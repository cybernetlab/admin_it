module ExtendIt
  module Config
    def self.use_refines(value = nil)
      if value.nil?
        @use_refines.nil? ? @use_refines = false : @use_refines
      else
        self.use_refines = value
      end
    end

    def self.use_refines=(value)
      unless RUBY_VERSION >= '2.1.0'
        fail(
          RuntimeError,
          'Refinements can be used only with ruby versions >= 2.1.0'
        )
      end
      @use_refines = value == true
    end

    def self.use_refines?
      @use_refines
    end
  end

  def self.config
    yield Config if block_given?
    Config
  end
end
