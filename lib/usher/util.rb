class Usher
  module Util
    autoload :Generators, File.join(File.dirname(__FILE__), 'util', 'generate')
    autoload :Parser, File.join(File.dirname(__FILE__), 'util', 'parser')
    autoload :Graph, File.join(File.dirname(__FILE__), 'util', 'graph')
  end
end