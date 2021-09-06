require 'json'

module JSF

  module ExampleLoading
    def gem_directory_path
      File.expand_path(File.dirname(__FILE__)) + '/../test/examples'
    end
    
    def parse_example(example_path)
      hash = JSON.parse(File.read(gem_directory_path + example_path))
      hash = yield (hash) if block_given?
      hash = hash.deep_symbolize_keys # change to deep_stringify_keys to run tests with string keys
      hash
    end
  end

  # module CoreExamples
  #   extend ExampleLoading
  # end

  # examples for all 'form' classes
  module FormExamples

    extend ExampleLoading

    def self.form(&block)
      parse_example('/forms/form.json', &block)
    end

    def self.response_set(&block)
      parse_example('/forms/response_set.json', &block)
    end

    def self.response(type, &block)
      hash = parse_example('/forms/response.json', &block)
      hash[type.to_s] || hash[type.to_sym]
    end

    def self.checkbox(&block)
      parse_example('/forms/field/checkbox.json', &block)
    end

    def self.component(&block)
      parse_example('/forms/field/component.json', &block)
    end

    def self.date_input(&block)
      parse_example('/forms/field/date_input.json', &block)
    end

    def self.header(&block)
      parse_example('/forms/field/header.json', &block)
    end

    def self.info(&block)
      parse_example('/forms/field/info.json', &block)
    end

    def self.number_input(&block)
      parse_example('/forms/field/number_input.json', &block)
    end

    def self.select(&block)
      parse_example('/forms/field/select.json', &block)
    end

    def self.slider(&block)
      parse_example('/forms/field/slider.json', &block)
    end

    def self.static(&block)
      parse_example('/forms/field/static.json', &block)
    end

    def self.switch(&block)
      parse_example('/forms/field/switch.json', &block)
    end

    def self.text_input(&block)
      parse_example('/forms/field/text_input.json', &block)
    end

    def self.file_input(&block)
      parse_example('/forms/field/file_input.json', &block)
    end

  end

end