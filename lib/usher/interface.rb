class Usher
  # Various interfaces for Usher.
  module Interface

    autoload(:Email,    File.join(File.dirname(__FILE__), 'interface', 'email'))
    autoload(:Merb,     File.join(File.dirname(__FILE__), 'interface', 'merb'))
    autoload(:Rails20,  File.join(File.dirname(__FILE__), 'interface', 'rails20'))
    autoload(:Rails22,  File.join(File.dirname(__FILE__), 'interface', 'rails22'))
    autoload(:Rails23,  File.join(File.dirname(__FILE__), 'interface', 'rails23'))
    autoload(:Rack,     File.join(File.dirname(__FILE__), 'interface', 'rack'))
    autoload(:Rails3,   File.join(File.dirname(__FILE__), 'interface', 'rails3'))
    autoload(:Text,     File.join(File.dirname(__FILE__), 'interface', 'text'))
    autoload(:Sinatra,  File.join(File.dirname(__FILE__), 'interface', 'sinatra'))

    def self.class_for(name)
      Usher::Interface.const_get(name.to_s.split(/_/).map{|e| e.capitalize}.join) or
        raise ArgumentError, "Interface #{name.inspect} doesn't exist."
    end

    # Usher::Interface.for(:rack, &block)
    def self.for(name, *args, &block)
      class_for(name).new(*args, &block)
    end

  end
end
