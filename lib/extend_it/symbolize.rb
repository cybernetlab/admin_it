module ExtendIt
  module Symbolize
    refine Object do
      def symbolize
        nil
      end

      def ensure_symbol
        nil
      end
    end

    refine String do
      def symbolize
        to_sym
      end

      def ensure_symbol
        to_sym
      end
    end

    refine Symbol do
      def symbolize
        self
      end

      def ensure_symbol
        self
      end
    end

    refine Array do
      def ensure_symbols
        flatten.map { |x| x.ensure_symbol }.compact
      end
    end
  end
end
