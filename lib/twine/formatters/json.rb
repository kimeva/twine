module Twine
  module Formatters
    class JQuery < Abstract
      include Twine::Placeholders
      
      def format_name
        'json'
      end

      def extension
        '.json'
      end

      def can_handle_directory?(path)
        Dir.entries(path).any? { |item| /^.+\.strings$/.match(item) }
      end

      def default_file_name(lang)
        return lang + ".json"
      end

      def determine_language_given_path(path)
        path_arr = path.split(File::SEPARATOR)
        path_arr.each do |segment|
          match = /^strings-(.+)$/.match(segment)
          if match
            return match[1]
          end
        end

        return
      end

      def output_path_for_language(lang)
        "./"
      end

      def read(io, lang)
        begin
          require "json"
        rescue LoadError
          raise Twine::Error.new "You must run 'gem install json' in order to read or write jquery-localize files."
        end

        json = JSON.load(io)
        json.each do |key, value|
          set_translation_for_key(key, lang, value)
        end
      end

      def format_file(lang)
        result = super
        return result unless result
        "{\n#{super}\n}\n"
      end

      def format_sections(twine_file, lang)
        sections = twine_file.sections.map { |section| format_section(section, lang) }
        sections.delete_if &:empty?
        sections.join(",\n\n")
      end

      def format_section_header(section)
      end

      def format_section(section, lang)
        definitions = section.definitions.dup

        definitions.map! { |definition| format_definition(definition, lang) }
        definitions.compact! # remove nil definitions
        definitions.join(",\n")
      end

      def key_value_pattern
        "\"%{key}\":\"%{value}\""
      end

      def format_key(key)
        escape_quotes(key)
      end

      def escape_value(value)
        # escape double and single quotes, & signs and tags
        value = escape_quotes(value)
        value.gsub!("'", "\\\\'")
        value.gsub!(/&/, '&amp;')
        value.gsub!('<', '&lt;')

        # escape non resource identifier @ signs (http://developer.android.com/guide/topics/resources/accessing-resources.html#ResourcesFromXml)
        resource_identifier_regex = /@(?!([a-z\.]+:)?[a-z+]+\/[a-zA-Z_]+)/   # @[<package_name>:]<resource_type>/<resource_name>
        value.gsub(resource_identifier_regex, '\@')
      end

      # see http://developer.android.com/guide/topics/resources/string-resource.html#FormattingAndStyling
      # however unescaped HTML markup like in "Welcome to <b>Android</b>!" is stripped when retrieved with getString() (http://stackoverflow.com/questions/9891996/)
      def format_value(value)
        value = value.dup

        # convert placeholders (e.g. %@ -> %s)
        value = convert_placeholders_from_twine_to_android(value)
        
        # replace beginning and end spaces with \u0020. Otherwise Android strips them.
        value.gsub(/\A *| *\z/) { |spaces| '\u0020' * spaces.length }
      end
    end
  end
end

Twine::Formatters.formatters << Twine::Formatters::JQuery.new
