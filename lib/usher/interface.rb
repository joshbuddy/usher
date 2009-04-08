$:.unshift File.dirname(__FILE__)

class Usher
  module Interface
    autoload :Rails2Interface, 'interface/rails2_interface'
    autoload :MerbInterface, 'interface/merb_interface'
    autoload :RackInterface, 'interface/rack_interface'
    
    def self.for(type, &blk)
      case type
      when :rails2
        Rails2Interface.new(&blk)
      when :merb
        MerbInterface.new(&blk)
      when :rack
        RackInterface.new(&blk)
      end
    end
    
    
  end
end