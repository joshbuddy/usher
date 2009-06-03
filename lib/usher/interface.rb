$:.unshift File.dirname(__FILE__)

class Usher
  module Interface
    autoload :Rails2_2Interface, 'interface/rails2_2_interface'
    autoload :Rails2_3Interface, 'interface/rails2_3_interface'
    autoload :MerbInterface, 'interface/merb_interface'
    autoload :RackInterface, 'interface/rack_interface'
    autoload :EmailInterface, 'interface/email_interface'
    
    def self.for(type, &blk)
      case type
      when :rails2_2
        Rails2_2Interface.new(&blk)
      when :rails2_3
        Rails2_3Interface.new(&blk)
      when :merb
        MerbInterface.new(&blk)
      when :rack
        RackInterface.new(&blk)
      when :email
        EmailInterface.new(&blk)
      end
      
    end
    
    
  end
end