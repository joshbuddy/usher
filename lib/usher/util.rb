class Usher
  module Util
    autoload :Generators, File.join('usher', 'util', 'generate')
    autoload :Parser,     File.join('usher', 'util', 'parser')
    autoload :Graph,      File.join('usher', 'util', 'graph')
    autoload :Mapper,     File.join('usher', 'util', 'mapper')
  end
end