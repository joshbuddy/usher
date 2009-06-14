class Usher
  module Interface
    autoload :Rails2_2Interface, File.join(File.dirname(__FILE__), 'interface', 'rails2_2_interface')
    autoload :Rails2_3Interface, File.join(File.dirname(__FILE__), 'interface', 'rails2_3_interface')
    autoload :MerbInterface, File.join(File.dirname(__FILE__), 'interface', 'merb_interface')
    autoload :RackInterface, File.join(File.dirname(__FILE__), 'interface', 'rack_interface')
    autoload :EmailInterface, File.join(File.dirname(__FILE__), 'interface', 'email_interface')
    
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