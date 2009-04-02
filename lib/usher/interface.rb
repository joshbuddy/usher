$:.unshift File.dirname(__FILE__)

class Usher
  module Interface
    autoload :Rails2Interface, 'interface/rails2_interface'
    autoload :MerbInterface, 'interface/merb_interface'
    autoload :RackInterface, 'interface/rack_interface'
    
    def self.for(type)
      case type
      when :rails2
        Rails2Interface.new
      when :merb
        MerbInterface.new
      when :rack
        RackInterface.new
      end
    end
    
    
  end
end