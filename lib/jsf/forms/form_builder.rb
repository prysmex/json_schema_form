# frozen_string_literal: true

require 'json'

module JSF
  module Forms

    #
    # Methods for loading examples used by JSF::Forms::FormBuilder
    #
    module FormExamples

      # Returns an example for a class
      #
      # @param [Class, String] klass
      # @param [Proc] &block <description>
      # @return [Hash]
      def example_for(klass, *, &)
        klass_name = klass.is_a?(String) ? klass : klass.name

        # demodulize and underscore class name
        underscore_name = klass_name.split('::').last.split(/(?=[A-Z])/).map(&:downcase).join('_')
        example(underscore_name, *, &)
      end

      # Returns an example based on a name
      #
      # @param [Class, String] klass
      # @param [Proc] &block
      # @return [Hash]
      def example(ex_name, *, &)
        path = case ex_name.to_s
          when 'shared_ref'
            '/shared_ref.json'
          when 'form'
            '/form.json'
          when 'response_set'
            '/response_set.json'
          when 'response'
            response_path(*)
          when 'section'
            '/section.json'
          # fields
          when 'checkbox'
            '/field/checkbox.json'
          when 'shared'
            '/field/shared.json'
          when 'date_input'
            '/field/date_input.json'
          when 'file_input'
            '/field/file_input.json'
          when 'geo_points'
            '/field/geo_points.json'
          when 'markdown'
            '/field/markdown.json'
          when 'number_input'
            '/field/number_input.json'
          when 'select'
            '/field/select.json'
          when 'signature'
            '/field/signature.json'
          when 'slider'
            '/field/slider.json'
          when 'static'
            '/field/static.json'
          when 'switch'
            '/field/switch.json'
          when 'text_input'
            '/field/text_input.json'
          when 'time_input'
            '/field/time_input.json'
          when 'video'
            '/field/video.json'
          else
            raise StandardError.new("invalid example name: #{ex_name}")
          end

        parse_example(path, &)
      end

      private

      # Returns a path for a path
      #
      # @param [Symbol] type
      # @return [String]
      def response_path(type = nil)
        if type
          "/response/#{type}.json"
        else
          '/response.json'
        end
      end

      # @param [String]
      def gem_directory_path
        File.expand_path(File.dirname(__FILE__)) + '/fixtures'
      end

      # Loads an example
      #
      # @param [String] example_path
      # @return [Hash]
      def parse_example(example_path)
        @file_cache ||= {}
        hash = @file_cache[example_path] ||= JSON.parse(File.read(gem_directory_path + example_path))
        hash = hash.deep_dup
        yield (hash) if block_given?
        hash = hash.deep_symbolize_keys # change to deep_stringify_keys to run tests with string keys
        hash
      end

    end

    #
    # Class that can be used to easily create JSF::Forms::Form instances
    #
    # @note should we deprecate this and just add the build method to JSF::Forms::Form?
    #
    class FormBuilder

      extend JSF::Forms::FormExamples

      def self.build(*, &)
        new(*, &).to_hash
      end

      def initialize(form = {}, &block)
        form = JSF::Forms::Form.new(form) unless form.is_a? JSF::Forms::Form
        unless form.is_a?(JSF::Forms::Form)
          raise TypeError.new("first argument must be a JSF::Forms::Form or a Hash instance, got a #{form.class}")
        end

        @form = form
        @block = block
      end

      # handle unknown methods by calling them to the form instance
      ruby2_keywords def method_missing(method_name, *, &)
        @form.public_send(method_name, *, &)
      end

      def to_hash
        instance_eval(&@block) if @block
        @form
      end

      # def example(*args, &block)
      #   self.class.example(*args, &block)
      # end

    end

  end
end