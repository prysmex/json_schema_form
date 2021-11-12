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
      def example_for(klass, *args, &block)
        klass_name = klass.is_a?(String) ? klass : klass.name

        # demodulize and underscore class name
        underscore_name = klass_name.split('::').last.split(/(?=[A-Z])/).map(&:downcase).join('_')
        example(underscore_name, *args, &block)
      end

      # Returns an example based on a name
      #
      # @param [Class, String] klass
      # @param [Proc] &block
      # @return [Hash]
      def example(ex_name, *args, &block)
        path = case ex_name.to_s
          when 'component_ref'
            '/component_ref.json'
          when 'form'
            '/form.json'
          when 'response_set'
            '/response_set.json'
          when 'response'
            response_path(*args)
          when 'checkbox'
            '/field/checkbox.json'
          when 'component'
            '/field/component.json'
          when 'date_input'
            '/field/date_input.json'
          when 'file_input'
            '/field/file_input.json'
          when 'header'
            '/field/header.json'
          when 'info'
            '/field/info.json'
          when 'number_input'
            '/field/number_input.json'
          when 'section'
            '/field/section.json'
          when 'select'
            '/field/select.json'
          when 'slider'
            '/field/slider.json'
          when 'static'
            '/field/static.json'
          when 'switch'
            '/field/switch.json'
          when 'text_input'
            '/field/text_input.json'
          else
            raise StandardError.new("invalid example name: #{ex_name}")
          end

        parse_example(path, &block)
      end

      private

      # Returns a path for a path
      #
      # @param [Symbol] type
      # @return [String]
      def response_path(type)
        if type == :is_inspection
          '/response_inspection.json'
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
    class FormBuilder

      extend JSF::Forms::FormExamples
    
      def self.build(*args, &block)
        new(*args, &block).to_hash
      end
    
      def initialize(form = {}, &block)
        form = JSF::Forms::Form.new(form) unless form.is_a? JSF::Forms::Form
        raise TypeError.new("first argument must be a JSF::Forms::Form or a Hash instance, got a #{form.class}") unless form.is_a?(JSF::Forms::Form) 
        @form = form
        @block = block
      end
    
      ruby2_keywords def method_missing(method_name, *args, &block)
        @form.public_send(method_name, *args, &block)
      end
    
      def to_hash
        instance_eval(&@block) if @block
        @form
      end
    
      def example(*args, &block)
        self.class.example(*args, &block)
      end
    
    end

  end
end