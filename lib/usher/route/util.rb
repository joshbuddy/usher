class Usher
  class Route

    module Util

      class Group < Array
        attr_accessor :group_type
        attr_accessor :parent

        def inspect
          "#{group_type}->#{super}"
        end

        def initialize(group_type, parent)
          @group_type = group_type
          @parent = parent
        end
      end

      def self.cartesian_product!(lval, rval)
        product = []
        (lval.size * rval.size).times do |index|
          val = []
          val.push(*lval[index % lval.size])
          val.push(*rval[index % rval.size])
          product << val
        end
        lval.replace(product)
      end

      def self.expand_path(parts)
        if parts.is_a?(Array)
          paths = [[]]
          
          unless parts.respond_to?(:group_type)
            new_parts = Group.new(:any, nil)
            parts.each{|p| new_parts << p}
            parts = new_parts
          end
          
          case parts.group_type
          when :all
            parts.each do |p|
              cartesian_product!(paths, expand_path(p))
            end
          when :any
            parts.each do |p|
              cartesian_product!(paths, expand_path(p))
            end
            paths.unshift([])
          when :one
            cartesian_product!(paths, parts.collect do |p|
              expand_path(p)
            end)
          end
          paths.each{|p| p.compact!; p.flatten! }
          paths
        else
          [[parts]]
        end

      end
    end
  end
end