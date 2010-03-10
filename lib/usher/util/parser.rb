require 'strscan'

class Usher
  module Util
    class Parser

      attr_reader :router

      def self.for_delimiters(router, valid_regex)
        new(
          router,
          Regexp.new('((:|\*)?' + valid_regex + '|' + router.delimiters_regex + '|\(|\)|\||\{)')
        )
      end

      def initialize(router, split_regex)
        @router = router
        @split_regex = split_regex
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
              if part.look_ahead && !part.look_ahead_priority
                part.look_ahead = nil
                part.look_ahead_priority = true
              else
                part.look_ahead = path[index + 1, path.size].find{|p| !p.is_a?(Usher::Route::Variable) && !router.delimiters.unescaped.include?(p)} || nil
              end
            when Usher::Route::Variable
              if part.look_ahead && !part.look_ahead_priority
                part.look_ahead = nil
                part.look_ahead_priority = true
              else
                part.look_ahead = router.delimiters.first_in(path[index + 1, path.size]) || router.delimiters.unescaped.first
              end
            end
          end
        end

        Route.new(
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
          when ?*
            var_name = part[1, part.size - 1].to_sym
            current_group << Usher::Route::Variable::Glob.new(part[1, part.size - 1], nil, requirements && requirements[var_name])
          when ?:
            var_name = part[1, part.size - 1].to_sym
            current_group << Usher::Route::Variable::Single.new(part[1, part.size - 1], nil, requirements && requirements[var_name])
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
            regex = Regexp.new(pattern)
            if variable
              variable_type = variable.slice!(0).chr.to_sym
              variable_class = case variable_type
              when :'!' then Usher::Route::Variable::Greedy
              when :*   then Usher::Route::Variable::Glob
              when :':' then Usher::Route::Variable::Single
              end
              variable_name = variable[0, variable.size - 1].to_sym
              current_group << variable_class.new(variable_name, regex, requirements && requirements[variable_name])
            elsif simple
              current_group << Usher::Route::Static::Greedy.new(Regexp.new(pattern))
            else
              current_group << regex
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