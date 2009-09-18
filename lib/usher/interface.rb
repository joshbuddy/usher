# From Extlib
module CamelCaseMixin
  def camel_case
    return self if self !~ /_/ && self =~ /[A-Z]+.*/
    split('_').map{|e| e.capitalize}.join
  end
end

# TODO: refactoring: I suggest to use usher/interfaces/rack.rb instead of
# usher/interface/rack_interface.rb, it will enable me to simplify this code
class Usher
  module Interface
    # Get root directory of interfaces of path to specified interface
    def self.interface_directory
      File.join(File.dirname(__FILE__), "interface")
    end

    # path to file
    def self.interface_path(name)
      File.join(self.interface_directory, "#{name}_interface.rb")
    end

    # Usher::Interface.for(:rack, &block)
    def self.for(name, &block)
      if File.exist?(self.interface_path(name))
        require self.interface_path(name)
        snake_cased = "#{name}_interface".extend(CamelCaseMixin)
        Usher::Interface.const_get(snake_cased.camel_case).new(&block)
      else
        raise ArgumentError, "Interface #{name} doesn't exist. Choose one of: #{self.interfaces.inspect}"
      end
    end

    # Array of symbols
    # Usher::Interface.interfaces
    # => [:email_interface, :merb_interface, :rack_interface, :rails2_2_interface, :rails2_3_interface, :rails3_interface, :text_interface]
    def self.interfaces
      Dir["#{self.interface_directory}/*.rb"].map do |interface|
        File.basename(interface).sub("_interface.rb", "").to_sym
      end
    end
  end
end
