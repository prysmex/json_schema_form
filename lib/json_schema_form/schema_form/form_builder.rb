
require_relative '../../../test/examples'

module SchemaForm
  class FormBuilder

    def self.build(*args, &block)
      new(*args, &block).to_hash
    end

    def initialize(form = {}, &block)
      form = SchemaForm::Form.new(form) if form.class == Hash
      raise TypeError.new("first argument must be a SchemaForm::Form or a Hash instance, got a #{form.class}") unless form.is_a?(SchemaForm::Form) 
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

    def example(name)
      JsonSchemaForm::SchemaFormExamples.send(name)
    end
  
  end
end