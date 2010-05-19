require 'strscan'

class Usher
  module Util
    class Parser

      attr_reader :router

      def initialize(router, valid_regex)
        @router = router
        @split_regex = Regexp.new('((:|\*)?' + valid_regex + '|' + router.delimiters_regex + '|\(|\)|\||\{)')
        @delimiters_regex = Regexp.new(router.delimiters_regex)
      end

      def generate_route(unprocessed_path, conditions, requirements, default_values, generate_with, priority)
        match_partially = false
        processed_path = unprocessed_path
        case unprocessed_path
        when String
          if unprocessed_path[-1] == ?*
            unprocessed_path.slice!(-1)
            match_partially = true
          end
          processed_path = parse(unprocessed_path, requirements, default_values)
        when Regexp
          processed_path = [Route::Static::Greedy.new(unprocessed_path)]
        when nil
          match_partially = true
        else
          match_partially = false
        end
        
        if processed_path && !processed_path.first.is_a?(Route::Util::Group)
          group = Usher::Route::Util::Group.new(:all, nil)
          processed_path.each{|p| group << p}
          processed_path = group
        end
        
        paths = processed_path.nil? ? [nil] : Route::Util.expand_path(processed_path)

        paths.each do |path|
          path && path.each_with_index do |part, index|
            part.default_value = default_values[part.name] if part.is_a?(Usher::Route::Variable) && default_values && default_values[part.name]
            case part
            when Usher::Route::Variable::Glob
              possible_look_ahead = path[index + 1, path.size].find{|p| !p.is_a?(Usher::Route::Variable) && !router.delimiters.unescaped.include?(p)} || nil
              if part.look_ahead && !part.look_ahead_priority && possible_look_ahead != part.look_ahead
                part.look_ahead = nil
                part.look_ahead_priority = true
              else
                part.look_ahead = path[index + 1, path.size].find{|p| !p.is_a?(Usher::Route::Variable) && !router.delimiters.unescaped.include?(p)} || nil
              end
            when Usher::Route::Variable
              possible_look_ahead = router.delimiters.first_in(path[index + 1, path.size]) || router.delimiters.unescaped.first
              if part.look_ahead && !part.look_ahead_priority && possible_look_ahead != part.look_ahead
                part.look_ahead = nil
                part.look_ahead_priority = true
              else
                part.look_ahead = router.delimiters.first_in(path[index + 1, path.size]) || router.delimiters.unescaped.first
              end
            end
          end
        end

        router.route_class.new(
          unprocessed_path,
          paths,
          router, 
          conditions, 
          requirements, 
          default_values, 
          generate_with,
          match_partially,
          priority
        )
      end

      def parse_and_expand(path, requirements = nil, default_values = nil)
        Usher::Route::Util.expand_path(parse(path, requirements, default_values))
      end

      def parse(path, requirements = nil, default_values = nil)
        parts = Usher::Route::Util::Group.new(:all, nil)
        scanner = StringScanner.new(path)

        current_group = parts
        part = nil
        while !scanner.eos?
          part ?
            (part << scanner.scan(@split_regex)) :
            (part = scanner.scan(@split_regex))

          if scanner.match?(/\\/) and !scanner.match?(@delimiters_regex)
            scanner.skip(/\\/)
            part << scanner.getch
            next
          end

          case part[0]
          when ?*, ?:
            variable_class = part[0] == ?* ? Usher::Route::Variable::Glob : Usher::Route::Variable::Single
            var_name = part[1, part.size - 1].to_sym
            current_group << variable_class.new(part[1, part.size - 1], requirements && requirements[var_name].is_a?(Regexp) ? requirements[var_name] : nil, requirements && requirements[var_name])
          when ?{
            pattern = ''
            count = 1
            simple = scanner.scan(/~/)
            variable = scanner.scan(/[!:\*]([^,]+),/)
            until count.zero?
              regex_part = scanner.scan(/\{|\}|[^\{\}]+/)
              case regex_part[0]
              when ?{
                count += 1
              when ?}
                count -= 1
              end
              pattern << regex_part
            end
            pattern.slice!(pattern.length - 1)
            if variable
              variable_class = case variable.slice!(0)
              when ?! then Usher::Route::Variable::Greedy
              when ?* then Usher::Route::Variable::Glob
              when ?: then Usher::Route::Variable::Single
              end
              variable_name = variable[0, variable.size - 1].to_sym
              raise DoubleRegexpException.new("#{variable_name} has two regex validators, #{pattern} and #{requirements[variable_name]}") if requirements && requirements[variable_name] && requirements[variable_name].is_a?(Regexp)
              current_group << variable_class.new(variable_name, Regexp.new(pattern), requirements && requirements[variable_name])
            elsif simple
              static = Usher::Route::Static::Greedy.new(pattern)
              static.generate_with = pattern
              current_group << static
            else
              simple_parts = pattern.split(',', 2)
              static = Usher::Route::Static::Greedy.new(Regexp.new(simple_parts.last))
              static.generate_with = simple_parts.first
              current_group << static
            end
          when ?(
            new_group = Usher::Route::Util::Group.new(:any, current_group)
            current_group << new_group
            current_group = new_group
          when ?)
            current_group = current_group.parent.group_type == :one ? current_group.parent.parent : current_group.parent
          when ?|
            unless current_group.parent.group_type == :one
              detached_group = current_group.parent.pop
              new_group = Usher::Route::Util::Group.new(:one, detached_group.parent)
              detached_group.parent = new_group
              detached_group.group_type = :all
              new_group << detached_group
              new_group.parent << new_group
            end
            current_group.parent << Usher::Route::Util::Group.new(:all, current_group.parent)
            current_group = current_group.parent.last
          when ?\\
            current_group << part[1..-1]
          else
            current_group << part
          end
          part = nil
        end unless !path || path.empty?
        parts
      end
    end
  end
end