# frozen_string_literal: true

#
# Collection of methods that allow defining tests independent of the field class name
#
# override: tested_klass
module FieldExampleHelpers

  def tested_klass
    name = self.class.name.sub('Test', '')
    Object.const_get("JSF::Forms::Field::#{name}")
  end

  def tested_klass_example
    JSF::Forms::FormBuilder.example_for(tested_klass)
  end

end
