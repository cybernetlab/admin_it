require 'thor'
require 'tilt'

# project compilation
class Compile < Thor
  FOLDERS = [File.join(Dir.pwd, 'src', 'templates')]

  # context
  class Context
    attr_reader :pwd

    def render_each(folder)
      return unless File.directory?(folder)
      Dir[File.join(folder, '**', '*.html.*')].each do |file|
        name = file.split('.')[0..-3].join('.')
        yield name, render(name)
      end
    end

    def include(name)
      FOLDERS.each do |folder|
        files = Dir[File.absolute_path(name, folder)]
        files.each { |file| return File.read(file) }
      end
      fail "Couldn't include #{name}"
    end

    def render(name)
      FOLDERS.each do |folder|
        files = Dir[File.absolute_path("#{name}.html.*", folder)]
        files.each do |file|
          @pwd = File.dirname(file)
          return Tilt.new(file).render(self)
        end
      end
      fail "Couldn't render #{name}"
    end
  end

  desc 'templates', 'compile templates'
  def templates
    files = Dir[File.join(Dir.pwd, '*.html.*')]
    FOLDERS.each { |folder| files += Dir[File.join(folder, '**', '*.html.*')] }
    context = Context.new
    files.each do |file|
      name = file.split('.')[0..-3].join('.')
      output = "#{name}.html"
      File.write(output, context.render(name))
    end
  end
end
