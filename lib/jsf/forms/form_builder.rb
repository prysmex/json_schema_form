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
      # @param [Symbol, String, nil] trait Optional example trait
      # @param [Proc] &block <description>
      # @return [Hash]
      def example_for(klass, trait = nil, &)
        klass_name = klass.is_a?(String) ? klass : klass.name

        # demodulize and underscore class name
        underscore_name = klass_name.split('::').last.split(/(?=[A-Z])/).map(&:downcase).join('_')
        example(underscore_name, trait, &)
      end

      # Returns an example based on a name
      #
      # When a trait is provided, loads the example from a nested path.
      # For example:
      #
      #   example('response', :scoring)
      #   # => /response/scoring.json
      #
      #   example('date_input', :date)
      #   # => /field/date_input/date.json
      #
      # @param [Class, String] ex_name
      # @param [Symbol, String, nil] trait Optional example trait
      # @param [Proc] &block
      # @return [Hash]
      def example(ex_name, trait = nil, &)
        path = case ex_name.to_s
          when 'shared_ref'
            '/shared_ref'
          when 'form'
            '/form'
          when 'response_set'
            '/response_set'
          when 'response'
            '/response'
          when 'section'
            '/section'
          # fields
          when 'checkbox'
            '/field/checkbox'
          when 'shared'
            '/field/shared'
          when 'date_input'
            '/field/date_input'
          when 'file_input'
            '/field/file_input'
          when 'geo_points'
            '/field/geo_points'
          when 'markdown'
            '/field/markdown'
          when 'number_input'
            '/field/number_input'
          when 'select'
            '/field/select'
          when 'signature'
            '/field/signature'
          when 'slider'
            '/field/slider'
          when 'static'
            '/field/static'
          when 'switch'
            '/field/switch'
          when 'text_input'
            '/field/text_input'
          when 'time_input'
            '/field/time_input'
          when 'video'
            '/field/video'
          when 'slideshow'
            '/field/slideshow'
          else
            raise StandardError.new("invalid example name: #{ex_name}")
          end

        path = "#{path}/#{trait}" if trait
        parse_example("#{path}.json", &)
      end

      private

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
        yield(hash) if block_given?
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