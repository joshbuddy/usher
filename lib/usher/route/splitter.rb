require 'strscan'

class Usher
  class Route
    class Splitter
      
      ScanRegex = /((:|\*||\.:|\.)[0-9A-Za-z\$\-_\+!\*',]+|\/|\(|\)|\|)/
      UrlScanRegex = /\/|\.?[0-9A-Za-z\$\-_\+!\*',]+/
      
      attr_reader :paths
      
      def initialize(path, requirements = {}, transformers = {})
        @parts = Splitter.split(path, requirements, transformers)
        @paths = calc_paths(@parts)
        @paths
      end

      def self.url_split(path)
        parts = []
        ss = StringScanner.new(path)
          while !ss.eos?
            if part = ss.scan(UrlScanRegex)
              parts << part unless part == '/'
            end
          end if path && !path.empty?
        parts
      end
      
      def self.split(path, requirements = {}, transformers = {})
        parts = Group.new(:all, nil)
        ss = StringScanner.new(path)
        current_group = parts
        while !ss.eos?
          part = ss.scan(ScanRegex)
          case part[0]
          when ?*, ?:, ?.
            type = (part[1] == ?: ? part.slice!(0,2) : part.slice!(0).chr).to_sym
            current_group << Variable.new(type, part, :validator => requirements[part.to_sym], :transformer => transformers[part.to_sym])
          when ?(
            new_group = Group.new(:any, current_group)
            current_group << new_group
            current_group = new_group
          when ?)            
            current_group = current_group.parent
          when ?|
            unless current_group.parent.type == :one
              detached_group = current_group.parent.pop
              new_group = Group.new(:one, detached_group.parent)
              detached_group.parent = new_group
              detached_group.type = :all
              new_group << detached_group
              new_group.parent << new_group
            end
            current_group.parent << Group.new(:all, current_group.parent)
            current_group = current_group.parent.last
          when ?/
          else
            current_group << part
          end
        end unless !path || path.empty?
        parts
      end
      
      private
      
      def cartesian_product!(lval, rval)
        product = []
        (lval.size * rval.size).times do |index|
          val = []
          val.push(*lval[index % lval.size])
          val.push(*rval[index % rval.size])
          product << val
        end
        lval.replace(product)
      end
      
      def calc_paths(parts)
        if parts.is_a?(Group)
          paths = [[]]
          case parts.type
          when :all
            parts.each do |p|
              cartesian_product!(paths, calc_paths(p))
            end
          when :any
            parts.each do |p|
              cartesian_product!(paths, calc_paths(p))
            end
            paths.unshift([])
          when :one
            cartesian_product!(paths, parts.collect do |p|
              calc_paths(p)
            end)
          end
          paths.each{|p| p.compact!; p.flatten! }
          paths
        else
          [[parts]]
        end
        
      end
      
      class Group < Array
        attr_accessor :type
        attr_accessor :parent
        
        def inspect
          "#{type}->#{super}"
        end
        
        def initialize(type, parent)
          @type = type
          @parent = parent
        end
      end
      
    end
  end
end