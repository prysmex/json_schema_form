require 'json'

module JsonSchemaForm

  module SchemaFormExamples

    def self.gem_directory_path
      File.expand_path(File.dirname(__FILE__)) + '/../test/examples'
    end
    
    def self.parse_example(example_path)
      hash = JSON.parse(File.read(gem_directory_path + example_path))
      hash = yield (hash) if block_given?
      hash = hash.deep_symbolize_keys # change to deep_stringify_keys to run tests with string keys
      hash
    end

    def self.form(&block)
      parse_example('/schema_form/form.json', &block)
    end

    def self.response_set(&block)
      parse_example('/schema_form/response_set.json', &block)
    end

    def self.response(type, &block)
      hash = parse_example('/schema_form/response.json', &block)
      hash[type.to_s] || hash[type.to_sym]
    end

    def self.checkbox(&block)
      parse_example('/schema_form/field/checkbox.json', &block)
    end

    def self.component(&block)
      parse_example('/schema_form/field/component.json', &block)
    end

    def self.date_input(&block)
      parse_example('/schema_form/field/date_input.json', &block)
    end

    def self.header(&block)
      parse_example('/schema_form/field/header.json', &block)
    end

    def self.info(&block)
      parse_example('/schema_form/field/info.json', &block)
    end

    def self.number_input(&block)
      parse_example('/schema_form/field/number_input.json', &block)
    end

    def self.select(&block)
      parse_example('/schema_form/field/select.json', &block)
    end

    def self.slider(&block)
      parse_example('/schema_form/field/slider.json', &block)
    end

    def self.static(&block)
      parse_example('/schema_form/field/static.json', &block)
    end

    def self.switch(&block)
      parse_example('/schema_form/field/switch.json', &block)
    end

    def self.text_input(&block)
      parse_example('/schema_form/field/text_input.json', &block)
    end

    def self.file_input(&block)
      parse_example('/schema_form/field/file_input.json', &block)
    end

  end

end