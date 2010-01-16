class Usher
  module Util
    autoload :Generators, File.join('usher', 'util', 'generate')
    autoload :Parser,     File.join('usher', 'util', 'parser')
  end
end