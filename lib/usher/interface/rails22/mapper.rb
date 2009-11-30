class Usher
  module Interface
    class Rails22
      
      class Mapper #:doc:
        def initialize(set) #:nodoc:
          @set = set
        end

        def connect(path, options = {})
          @set.add_route(path, options)
        end

        def root(options = {})
          if options.is_a?(Symbol)
            if source_route = @set.named_routes[options]
              options = source_route.conditions.blank? ? 
                source_route.options.merge({ :conditions => source_route.conditions }) : source_route.options
            end
          end
          named_route(:root, '/', options)
        end

        def named_route(name, path, options = nil)
          @set.add_named_route(name, path, options)
        end

        def namespace(name, options = {}, &block)
          if options[:namespace]
            with_options({:path_prefix => "#{options.delete(:path_prefix)}/#{name}", :name_prefix => "#{options.delete(:name_prefix)}#{name}_", :namespace => "#{options.delete(:namespace)}#{name}/" }.merge(options), &block)
          else
            with_options({:path_prefix => name, :name_prefix => "#{name}_", :namespace => "#{name}/" }.merge(options), &block)
          end
        end

        def method_missing(route_name, *args, &proc) #:nodoc:
          super unless args.length >= 1 && proc.nil?
          @set.add_named_route(route_name, *args)
        end
      end

    end
  end
end
