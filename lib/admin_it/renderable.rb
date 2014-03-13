module AdminIt
  module Renderable
    def render(entity = nil, instance = nil, &block)
      if entity.nil? && instance.nil?
        # method used as setter - just save block
        @renderer = block if block_given?
      elsif !@renderer.nil?
        # method used as event emmiter, call block in instance or caller
        # context if it present
        if instance.nil?
          @renderer.call(entity)
        else
          instance.instance_exec(entity, &@renderer)
        end
      end
    end
  end
end
