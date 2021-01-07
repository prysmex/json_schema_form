# JsonSchemaForm

This gem is powered by [superhash](https://github.com/prysmex/super_hash) so you might need to get familiar with it before starting.

Validations are powered by Dry::Schema [dry-schema](https://dry-rb.org/gems/dry-schema)

JsonSchemaForm gem is designed to contain the backing classes for form definitions that are based on json schema standard [json_schema](https://json-schema.org/). There are some differences between the standard schemas and the ones defined by JsonSchemaForm::Form::Form, mainly to support:
 - Response sets
 - Display properties
 - versioning and version migration
 
The classes can be divided into the following 'modules':

### json_schema:
Can be used to back plain and standard [json_schema](https://json-schema.org/) schemas. They all inherit from `JsonSchemaForm::JsonSchema::Base`
 - JsonSchemaForm::JsonSchema::Array
 - JsonSchemaForm::JsonSchema::Boolean
 - JsonSchemaForm::JsonSchema::Null
 - JsonSchemaForm::JsonSchema::Number
 - JsonSchemaForm::JsonSchema::Object
 - JsonSchemaForm::JsonSchema::String
    
### field:
These classes are used by JsonSchemaForm::Form to define its properties or 'fields', they inherit from JsonSchemaForm::JsonSchema::... classes.
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
 
### form:
Inherits from `JsonSchemaForm::JsonSchema::Object`, but adds some features used by forms.
 - JsonSchemaForm::Form

### document:
Used by Prysmex as the 'raw data' that is created when a form is filled.
 - JsonSchemaForm::Document::Document => Main class for storing 'raw data'
 - JsonSchemaForm::Document::Extras => used by Inspection only
 - JsonSchemaForm::Document::Meta => used by Inspection only
    
### response:
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

### json_schema:

Let's create a simple number schema by using it's backing class.

These methods are available in all JsonSchemaForm::JsonSchema::* classes:
- validations => returns any json schema validations
- validation_schema => returns the instance of Dry::Schema::Processor used to validate the schema
- schema_validation_hash => returns a the hash that will be used by the validation_schema, it may be a subset of the schema object
- schema_errors => returns a hash with the errors found
- valid_with_schema? => returns true if no errors
- required? => returns true if validations include required
- key_name => returns extracts the last part of the $id value
- meta => returns a hash with metadata (parent object, object path, ...)

```ruby
number_schema = JsonSchemaForm::JsonSchema::Number.new({
 type: 'number'
})
number_schema # => {
 :type=>"number",
 :$id=>"http://example.com/example.json",
 :$schema=>"http://json-schema.org/draft-07/schema#"
}


# now lets create a more interesting schema
object_schema = JsonSchemaForm::JsonSchema::Object.new({
  "$id": "http://example.com/example.json",
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "title": "Test",
  "some_invalid_key": 1,
  "required": [
    "size"
  ],
  "properties": {
    "empty": {
      "$id": "/properties/empty",
      "type": "null",
      "title": "empty",
      "another_invalid_key": "oh oh"
    },
    "size": {
      "$id": "/properties/size",
      "type": "number",
      "title": "size"
    }
  }
})

object_schema.validations # => {:empty=>{:required=>false}, :size=>{:required=>true}}
object_schema.schema_validation_hash # => {:$id=>"http://example.com/example.json", :$schema=>"http://json-schema.org/draft-07/schema#", :type=>"object", :title=>"Test", :some_invalid_key=>1, :required=>["size"], :properties=>{}, :allOf=>[]}
object_schema.schema_errors # => {:some_invalid_key=>["is not allowed"], :properties=>{:empty=>{"another_invalid_key"=>["is not allowed"]}}}
object_schema.valid_with_schema? # => false

prop = object_schema[:properties][:size]
prop.class # => JsonSchemaForm::JsonSchema::Number
prop.required? # => true
prop.key_name # => "size"
object_schema.meta # => {
  :parent=>{:$id=>"http://example.com/example.json", :$schema=>"http://json-schema.org/draft-07/schema#", :type=>"object", :title=>"Test", :some_invalid_key=>1, :required=>["size"], :properties=>{:empty=>{:$id=>"/properties/empty", :type=>"null", :title=>"empty", :another_invalid_key=>"oh oh", :$schema=>"http://json-schema.org/draft-07/schema#"}, :size=>{:$id=>"/properties/size", :type=>"number", :title=>"size", :$schema=>"http://json-schema.org/draft-07/schema#"}}, :allOf=>[]},
  :path=>[:properties, :size]
}
```
    
### field:



### form:

### document:
    
### response:

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/json_schema_form.
