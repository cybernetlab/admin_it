module ExtendIt
  module Ensures
    VAR_REGEXP = /\A
      (?<class_access>@{1,2})?
      (?<name>[a-z_][a-zA-Z_0-9]*)
      (?<modifier>[?!=])?
    \z/x
  end
end

if ExtendIt.config.use_refines?
  module ExtendIt
    module Ensures
      refine Object do
        def ensure_symbol; end
        def ensure_instance_variable_name; end
        def ensure_setter_name; end
        def ensure_checker_name; end
        def ensure_bang_name; end
        def ensure_local_name; end
      end

      refine String do
        def ensure_symbol
          to_sym
        end

        def ensure_symbols
          [to_sym]
        end

        def ensure_instance_variable_name
          matches = VAR_REGEXP.match(self)
          matches.nil? ? nil : "@#{matches[:name]}".to_sym
        end

        def ensure_setter_name
          matches = VAR_REGEXP.match(self)
          matches.nil? ? nil : "#{matches[:name]}=".to_sym
        end

        def ensure_checker_name
          matches = VAR_REGEXP.match(self)
          matches.nil? ? nil : "#{matches[:name]}?".to_sym
        end

        def ensure_bang_name
          matches = VAR_REGEXP.match(self)
          matches.nil? ? nil : "#{matches[:name]}!".to_sym
        end

        def ensure_local_name
          matches = VAR_REGEXP.match(self)
          matches.nil? ? nil : matches[:name].to_sym
        end
      end

      refine Symbol do
        def ensure_symbol
          self
        end

        def ensure_symbols
          [self]
        end

        def ensure_instance_variable_name
          matches = VAR_REGEXP.match(to_s)
          matches.nil? ? nil : "@#{matches[:name]}".to_sym
        end

        def ensure_setter_name
          matches = VAR_REGEXP.match(to_s)
          matches.nil? ? nil : "#{matches[:name]}=".to_sym
        end

        def ensure_checker_name
          matches = VAR_REGEXP.match(to_s)
          matches.nil? ? nil : "#{matches[:name]}?".to_sym
        end

        def ensure_bang_name
          matches = VAR_REGEXP.match(to_s)
          matches.nil? ? nil : "#{matches[:name]}!".to_sym
        end

        def ensure_local_name
          matches = VAR_REGEXP.match(to_s)
          matches.nil? ? nil : matches[:name].to_sym
        end
      end

      refine Array do
        def ensure_symbols
          flatten.map { |x| x.ensure_symbol }.compact
        end
      end
    end
  end
else
  module ExtendIt
    module Ensures; end
  end

  class Object
    def ensure_symbol; end
    def ensure_instance_variable_name; end
    def ensure_setter_name; end
    def ensure_checker_name; end
    def ensure_bang_name; end
    def ensure_local_name; end

    def ensure_symbols
      []
    end
  end

  class String
    def ensure_symbol
      to_sym
    end

    def ensure_symbols
      [to_sym]
    end

    def ensure_instance_variable_name
      matches = ExtendIt::Ensures::VAR_REGEXP.match(self)
      matches.nil? ? nil : "@#{matches[:name]}".to_sym
    end

    def ensure_setter_name
      matches = ExtendIt::Ensures::VAR_REGEXP.match(self)
      matches.nil? ? nil : "#{matches[:name]}=".to_sym
    end

    def ensure_checker_name
      matches = ExtendIt::Ensures::VAR_REGEXP.match(self)
      matches.nil? ? nil : "#{matches[:name]}?".to_sym
    end

    def ensure_bang_name
      matches = ExtendIt::Ensures::VAR_REGEXP.match(self)
      matches.nil? ? nil : "#{matches[:name]}!".to_sym
    end

    def ensure_local_name
      matches = ExtendIt::Ensures::VAR_REGEXP.match(self)
      matches.nil? ? nil : matches[:name].to_sym
    end
  end

  class Symbol
    def ensure_symbol
      self
    end

    def ensure_symbols
      [self]
    end

    def ensure_instance_variable_name
      matches = ExtendIt::Ensures::VAR_REGEXP.match(to_s)
      matches.nil? ? nil : "@#{matches[:name]}".to_sym
    end

    def ensure_setter_name
      matches = ExtendIt::Ensures::VAR_REGEXP.match(to_s)
      matches.nil? ? nil : "#{matches[:name]}=".to_sym
    end

    def ensure_checker_name
      matches = ExtendIt::Ensures::VAR_REGEXP.match(to_s)
      matches.nil? ? nil : "#{matches[:name]}?".to_sym
    end

    def ensure_bang_name
      matches = ExtendIt::Ensures::VAR_REGEXP.match(to_s)
      matches.nil? ? nil : "#{matches[:name]}!".to_sym
    end

    def ensure_local_name
      matches = ExtendIt::Ensures::VAR_REGEXP.match(to_s)
      matches.nil? ? nil : matches[:name].to_sym
    end
  end

  class Array
    def ensure_symbols
      flatten.map { |x| x.ensure_symbol }.compact
    end
  end
end
