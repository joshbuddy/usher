class Usher
  # Various interfaces for Usher.
  module Interface

    autoload(:Rails20,  File.join(File.dirname(__FILE__), 'interface', 'rails20'))
    autoload(:Rails22,  File.join(File.dirname(__FILE__), 'interface', 'rails22'))
    autoload(:Rails23,  File.join(File.dirname(__FILE__), 'interface', 'rails23'))
    autoload(:Rack,     File.join(File.dirname(__FILE__), 'interface', 'rack'))
    autoload(:Rails3,   File.join(File.dirname(__FILE__), 'interface', 'rails3'))
    autoload(:Sinatra,  File.join(File.dirname(__FILE__), 'interface', 'sinatra'))
    
    # Returns the appropriate interface class for a given name.
    # @param name [Symbol, String] The interface you wish to load. This can be `:rails20`, `:rails22`, `:rails23`, `:rack`, `:rails3` or  `:sinatra`
    def self.class_for(name)
      Usher::Interface.const_get(name.to_s.split(/_/).map{|e| e.capitalize}.join) or
        raise ArgumentError, "Interface #{name.inspect} doesn't exist."
    end

    # Returns the appropriate interface class for a given name.
    # @param name [Symbol, String] The interface you wish to load. This can be `:rails20`, `:rails22`, `:rails23`, `:rack`, `:rails3` or  `:sinatra`
    # @param args [Object] Any additional parameters the interface wishes to recieve
    # @return [Object] An intatiated interface
    def self.for(name, *args, &block)
      class_for(name).new(*args, &block)
    end

  end
end
