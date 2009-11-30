class Usher
  module Interface

    InterfaceRegistry = {}

    def self.register(name, cls)
      InterfaceRegistry[name] = cls
    end

    register(:email,    File.join(File.dirname(__FILE__), 'interface', 'email'))
    register(:merb,     File.join(File.dirname(__FILE__), 'interface', 'merb'))
    register(:rails20,  File.join(File.dirname(__FILE__), 'interface', 'rails20'))
    register(:rails22,  File.join(File.dirname(__FILE__), 'interface', 'rails22'))
    register(:rails23,  File.join(File.dirname(__FILE__), 'interface', 'rails23'))
    register(:rack,     File.join(File.dirname(__FILE__), 'interface', 'rack'))
    register(:rails3,   File.join(File.dirname(__FILE__), 'interface', 'rails3'))
    register(:text,     File.join(File.dirname(__FILE__), 'interface', 'text'))

    # Usher::Interface.for(:rack, &block)
    def self.for(name, &block)
      name = name.to_sym
      if InterfaceRegistry[name]
        require InterfaceRegistry[name]
        const = Usher::Interface.const_get(File.basename(InterfaceRegistry[name]).to_s.split(/_/).map{|e| e.capitalize}.join)
        const.new(&block)
      else
        raise ArgumentError, "Interface #{name.inspect} doesn't exist. Choose one of: #{InterfaceRegistry.keys.inspect}"
      end
    end

  end
end
