class Usher
  module Interface

    InterfaceRegistry = {}

    def self.register(name, cls)
      InterfaceRegistry[name] = cls
    end

    register(:email,    File.join(~'interface', 'email'))
    register(:merb,     File.join(~'interface', 'merb'))
    register(:rails22,  File.join(~'interface', 'rails22'))
    register(:rails23,  File.join(~'interface', 'rails23'))
    register(:rack,     File.join(~'interface', 'rack'))
    register(:rails3,   File.join(~'interface', 'rails3'))
    register(:text,     File.join(~'interface', 'text'))

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
