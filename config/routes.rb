AdminIt::Engine.routes.draw do
  AdminIt.resources.each do |name, resource|
    resources(resource.plural,
              controller: "admin_it/#{name}",
              except: [:index]) do
      resource.collections.each do |context|
        next unless context.collection?
        get context.context_name, on: :collection
      end
      unless resource.collections.empty?
        get('/', on: :collection, action: resource.default_context)
      end
    end
  end
  unless AdminIt.resources.empty?
    name, resource = AdminIt.resources.first
    get('/',
        controller: "admin_it/#{name}",
        action: resource.default_context)
  end
end
