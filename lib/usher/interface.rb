class Usher
  module Interface
    autoload :Rails2_2Interface, File.join(File.dirname(__FILE__), 'interface', 'rails2_2_interface')
    autoload :Rails2_3Interface, File.join(File.dirname(__FILE__), 'interface', 'rails2_3_interface')
    autoload :MerbInterface, File.join(File.dirname(__FILE__), 'interface', 'merb_interface')
    autoload :RackInterface, File.join(File.dirname(__FILE__), 'interface', 'rack_interface')
    autoload :EmailInterface, File.join(File.dirname(__FILE__), 'interface', 'email_interface')
    autoload :Rails3Interface, File.join(File.dirname(__FILE__), 'interface', 'rails3_interface')
    
    def self.for(type, &blk)
      class_for(type).new(&blk)
    end
    
    def self.class_for(type)
      case type
      when :rails2_2
        Rails2_2Interface
      when :rails2_3
        Rails2_3Interface
      when :merb
        MerbInterface
      when :rack
        RackInterface
      when :email
        EmailInterface
      when :rails3
        Rails3Interface
      end
      
    end
    
    
  end
end