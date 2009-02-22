$:.unshift File.dirname(__FILE__)

class Usher
  module Interface
    
    def self.for(type)
      case type
      when :rails2
        require 'interface/rails2'
        Rails2.new
      end
    end
    
    
  end
end