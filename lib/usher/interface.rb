$:.unshift File.dirname(__FILE__)

class Usher
  module Interface
    
    def self.for(type)
      case type
      when :rails2
        require 'interface/rails2_interface'
        Rails2Interface.new
      when :merb
        require 'interface/merb_interface'
        MerbInterface.new
      when :rack
        require 'interface/rack_interface'
        RackInterface.new
      end
    end
    
    
  end
end