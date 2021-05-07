require 'json'

module JsonSchemaForm
  module Examples

    def gem_directory_path
      File.expand_path(File.dirname(__FILE__)) + '/../test/examples'
    end
    
    def parse_example(example_path, options={})
      options = {symbolized: true}.merge(options)
      hash = JSON.parse(File.read(gem_directory_path + example_path))
      hash = SuperHash::DeepKeysTransform.symbolize_recursive(hash) if options[:symbolized]
      hash
    end

  end

  module SchemaFormExamples
    extend JsonSchemaForm::Examples

    def self.form(options={})
      parse_example('/schema_form/form.json', options)
    end

    def self.response_set(options={})
      parse_example('/schema_form/response_set.json', options)
    end

    def self.response(options={})
      parse_example('/schema_form/response.json', options)
    end

    def self.checkbox(options={})
      parse_example('/schema_form/field/checkbox.json', options)
    end

    def self.component(options={})
      parse_example('/schema_form/field/component.json', options)
    end

    def self.date_input(options={})
      parse_example('/schema_form/field/date_input.json', options)
    end

    def self.header(options={})
      parse_example('/schema_form/field/header.json', options)
    end

    def self.info(options={})
      parse_example('/schema_form/field/info.json', options)
    end

    def self.number_input(options={})
      parse_example('/schema_form/field/number_input.json', options)
    end

    def self.select(options={})
      parse_example('/schema_form/field/select.json', options)
    end

    def self.slider(options={})
      parse_example('/schema_form/field/slider.json', options)
    end

    def self.static(options={})
      parse_example('/schema_form/field/static.json', options)
    end

    def self.switch(options={})
      parse_example('/schema_form/field/switch.json', options)
    end

    def self.text_input(options={})
      parse_example('/schema_form/field/text_input.json', options)
    end

    def self.file_input(options={})
      parse_example('/schema_form/field/file_input.json', options)
    end

  end

end