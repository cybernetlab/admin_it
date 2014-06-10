module AdminIt
  # Middleware request
  class Request < DelegateClass(Hash)
    ENV_KEY = 'admin_it.request'

    attr_reader :templates

    def initialize(env)
      @templates = {}
      @collections = {}
      @models = {}
      @env = env
      @process = false
      super({})
    end

    def process?
      @process == true
    end

    def process!
      @process = true
    end

    def self.get(request)
      return request if request.is_a?(self)
      fail 'Wrong request' unless request.is_a?(Rack::Request)
      request = request.env[ENV_KEY]
      fail 'rails_script middleware is not mounted' if request.nil?
      request
    end
  end

  # AdminIt middleware
  class Middleware
    SUBST_REGEXP = /<!--\s*(?<name>[a-zA-Z0-9_]+)\s*-->/

    def initialize(app)
      @app = app
    end

    def call(env)
      request = env[Request::ENV_KEY] = Request.new(env)
      status, headers, body = @app.call(env)
      if request.process?
        length = 0
        body.each do |str|
          str.gsub!(SUBST_REGEXP) { |s| request[SUBST_REGEXP.match(s)[1]] }
          length += str.size
        end
        headers['Content-Length'] = length.to_s
      end
      [status, headers, body]
    end
  end
end
