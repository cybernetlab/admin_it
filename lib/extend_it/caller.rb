require 'continuation' if RUBY_VERSION >= '1.9.0'

module ExtendIt
  module Caller
    # http://rubychallenger.blogspot.ru/2011/07/caller-binding.html
    refine Object do
      def caller_binding
        cc, count = nil, 0
        set_trace_func(lambda { |event, file, lineno, id, binding, klass|
          if count == 2
            set_trace_func nil
            cc.call(binding)
          elsif event == 'return'
            count += 1
          end
        })
        return callcc { |cont| cc = cont }
      end

      def caller_eval(str)
        cc, ok = nil, false
        set_trace_func(lambda { |event, file, lineno, id, binding, klass|
          if ok
            set_trace_func nil
            cc.call(binding)
          else
            ok = event == "return"
          end
        })
        return unless bb = callcc { |c| cc = c; nil }
        eval(str, bb)
      end
    end
  end
end
