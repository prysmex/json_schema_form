
require_relative '../../../test/examples'

module JSF
  module Forms
    class FormBuilder
    
      def self.build(*args, &block)
        new(*args, &block).to_hash
      end
    
      def initialize(form = {}, &block)
        form = JSF::Forms::Form.new(form) unless form.is_a? JSF::Forms::Form
        raise TypeError.new("first argument must be a JSF::Forms::Form or a Hash instance, got a #{form.class}") unless form.is_a?(JSF::Forms::Form) 
        @form = form
        @block = block
      end
    
      def method_missing(method_name, *args, &block)
        @form.public_send(method_name, *args, &block)
      end
    
      def to_hash
        instance_eval(&@block)
        @form
      end
    
      def example(name, *args)
        JSF::FormExamples.send(name, *args)
      end
    
    end
  end
end