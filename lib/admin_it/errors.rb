module AdminIt
  class Error < StandardError; end
  class FieldReadError < Error; end
  class FieldWriteError < Error; end
end
