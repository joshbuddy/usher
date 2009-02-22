class Usher
  module Interface
    class Rails2
      module Route
        
        def to(options)
          @params = options
          raise "route #{original_path} must include a controller" unless @dynamic_set.include?(:controller) || @params.include?(:controller)
          self
        end
        
      end
    end
  end
end