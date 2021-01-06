# JsonSchemaForm

JsonSchemaForm gem is designed to contain the backing classes for form definitions that are based on json schema standard [json_schema](https://json-schema.org/). There are some differences between the standard schemas and the ones defined by JsonSchemaForm::Form::Form, mainly to support:
 - Response sets
 - Display properties
 - schemaFormVersion (versioning)
 
This gem is powered by [superhash](https://github.com/prysmex/super_hash) so you might need to get familiar with it before starting.
 
The classes can be divided into the following 'modules':
#### json_schema:
Can be used to back plain and standard [json_schema](https://json-schema.org/) schemas. They all inherit from `JsonSchemaForm::JsonSchema::Base`
 - JsonSchemaForm::JsonSchema::Array
 - JsonSchemaForm::JsonSchema::Boolean
 - JsonSchemaForm::JsonSchema::Null
 - JsonSchemaForm::JsonSchema::Number
 - JsonSchemaForm::JsonSchema::Object
 - JsonSchemaForm::JsonSchema::String
    
#### form:
Inherits from `JsonSchemaForm::JsonSchema::Object`, but adds some features used by forms and validations powered by Dry::Schema [dry-schema](https://dry-rb.org/gems/dry-schema)
 - JsonSchemaForm::Form
    
#### field:
These classes are used by JsonSchemaForm::Form to define its properties or 'fields'
 - JsonSchemaForm::Field::Checkbox
 - JsonSchemaForm::Field::DateInput
 - JsonSchemaForm::Field::Header
 - JsonSchemaForm::Field::Info
 - JsonSchemaForm::Field::NumberInput
 - JsonSchemaForm::Field::Select
 - JsonSchemaForm::Field::Slider
 - JsonSchemaForm::Field::Static
 - JsonSchemaForm::Field::Switch
 - JsonSchemaForm::Field::TextInput

#### document:
Used by Prysmex as the 'raw data' that is created when a form is filled.
 - JsonSchemaForm::Document::Document => Main class for storing 'raw data'
 - JsonSchemaForm::Document::Extras => used by Inspection only
 - JsonSchemaForm::Document::Meta => used by Inspection only
    
#### response:
 - JsonSchemaForm::ResponseSet => a ::ResponseSet contains many ::Response
 - JsonSchemaForm::Response

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'json_schema_form'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install json_schema_form

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/json_schema_form.
