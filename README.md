# JsonSchemaForm

JsonSchemaForm gem provides a simple and extensible API to create backing classes for json_schema hashes [json_schema](https://json-schema.org/) so you don't mess around with POROs.

In addition, this gem has build-in classes that provide form-like functionality that are based on json_schema.

To do this, this gem is powered by [superhash](https://github.com/prysmex/super_hash) so you might want to get familiar with it before starting.
Default validations are powered by Dry::Schema [dry-schema](https://dry-rb.org/gems/dry-schema)

## JsonSchema

This is the backbone and provides multiple ruby `Module`s that are used to easily create a backing class for a json_schema object
- Arrayable     (methods when type `key` equals or contains `array`)
- Booleanable   (methods when type `key` equals or contains `boolean`)
- Buildable     (sets transforms used to create recursive tree structures)
- Nullable      (methods when type `key` equals or contains `null`)
- Numberable    (methods when type `key` equals or contains `number`)
- Objectable    (methods when type `key` equals or contains `object`)
- Schemable     (base methods are in a module yo avoid creatinga Base class)
- Stringable    (methods when type `key` equals or contains `string`)

This is exactly how to pre-wired `Schema` class is created
```ruby
module JsonSchema
  class Schema < ::SuperHash::Hasher
    
    include JsonSchema::SchemaMethods::Schemable
    include JsonSchema::SchemaMethods::Buildable
    include JsonSchema::SchemaMethods::Objectable
    include JsonSchema::SchemaMethods::Stringable
    include JsonSchema::SchemaMethods::Numberable
    include JsonSchema::SchemaMethods::Booleanable
    include JsonSchema::SchemaMethods::Arrayable
    include JsonSchema::SchemaMethods::Nullable
    
  end
end

schema = JsonSchema::Schema.new({properties: {prop1: {type: 'string'}}})
schema.class #=> JsonSchema::Schema
schema[:properties][:prop1].class #=> JsonSchema::Schema
```

In addition to this, you can add validations to your objects by using the `JsonSchema::Validations::Validatable` module.
A basic validation example would be this

```ruby
class MySchema < ::SuperHash::Hasher
   
  include JsonSchema::SchemaMethods::Schemable
  include JsonSchema::SchemaMethods::Buildable #required for validations
  include JsonSchema::Validations::Validatable

  def own_errors(passthru)
    errors_hash = {}
    errors_hash[:$id] = 'id must be present' if self[:$id].nil?
    errors_hash
  end

end

schema = MySchema.new(type: 'array', items: [{type: 'string'}])
schema.errors #=> {:$id=>"id must be present", :items=>{0=>{:$id=>"id must be present"}}}
```

    
### form/field:

To view some examples, check `spec/examples`

### document:
Used by Prysmex as the 'raw data' that is created when a form is filled.
 - `JsonSchemaForm::Document::Document` main class for storing 'raw data'
 - `JsonSchemaForm::Document::Extras` used by Inspection only
 - `JsonSchemaForm::Document::Meta` used by Inspection only
    
### response:
 - `JsonSchemaForm::ResponseSet`
 - `JsonSchemaForm::Response` is contained by `::ResponseSet`

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

These methods are available in all `JsonSchema::SchemaMethods::*` classes:
- `validations` returns any json schema validations
- `validation_schema` returns the instance of Dry::Schema::Processor used to validate the schema
- `schema_validation_hash` returns a the hash that will be used by the validation_schema, it may be a subset of the schema object
- `schema_errors` returns a hash with the errors found
- `required?` returns true if validations include required
- `key_name` ToDo
- `meta` returns a hash with metadata (parent object, object path, ...)
- `root_parent`
only: (Array, Boolean, Null, Number, String)
- `dependent_conditions`
- `has_dependent_conditions?`
- `dependent_conditions_for_value(value) {|condition, value| some_schema_validation }`

In addition to the previous methods, the `JsonSchema::SchemaMethods::Object` class has the following methods:
property management:
- `add_property(id, definition)`
- `remove_property(id)`
validation management:
- `add_required_property(name)`
- `remove_required_property(name)`
getters:
- `properties`
- `dynamic_properties(levels=nil)`
- `merged_properties(levels=nil)`
- `property_names`
- `dynamic_property_names(levels=nil)`
- `merged_property_names(levels=nil)`
- `get_property(property)`
- `get_dynamic_property(property, levels=nil)`
- `get_merged_property(property, levels=nil)`
- `has_property?(property)`
- `has_dynamic_property?(property, levels=nil)`
- `has_merged_property?(property, levels=nil)`
- `property_type(property)`
- `dynamic_property_type(property, levels=nil)`
- `merged_property_type(property, levels=nil)`
- `properties_type_mapping`
- `dynamic_properties_type_mapping(levels=nil)`
- `merged_properties_type_mapping(levels=nil)`

Let's create a simple number schema by using it's backing class.

```ruby
number_schema = JsonSchema::SchemaMethods::Number.new({
 type: 'number'
})
number_schema
# => {
# :type=>"number",
# :$id=>"http://example.com/example.json",
# :$schema=>"http://json-schema.org/draft-07/schema#"
#}
```

Now lets create a more interesting object schema containing a null and a number schema as properties
```ruby
object_schema = JsonSchema::SchemaMethods::Object.new({
  "$id": "http://example.com/example.json",
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "title": "Test",
  "some_invalid_key": 1,
  "required": [
    "age"
  ],
  "properties": {
    "name": {
      "$id": "/properties/name",
      "type": "null",
      "title": "name",
      "another_invalid_key": "oh oh"
    },
    "age": {
      "$id": "/properties/age",
      "type": "number",
      "title": "age"
    }
  },
  "allOf":[
    {
      "if": {
        "properties": {
          "name": {
            "const": "Luke"
          }
        }
      },
      "then": {
        "properties": {
          "is_it_luke_skywalker?": {
            "$id": "/properties/is_it_luke_skywalker?",
            "title": "is_it_luke_skywalker?",
            "yet_another_invalid_key": "oh oh",
            "type": "boolean",
            "$schema": "http://json-schema.org/draft-07/schema#"
          }
        },
        "$id": "http://example.com/example.json",
        "$schema": "http://json-schema.org/draft-07/schema#",
        "required": [],
        "allOf": []
      }
    }
  ]
})

# inspecting the object_schema
object_schema.validations
# => {:name=>{:required=>false}, :age=>{:required=>true}}
object_schema.schema_validation_hash
# => {:$id=>"http://example.com/example.json", :$schema=>"http://json-schema.org/draft-07/schema#", :type=>"object", :title=>"Test", :some_invalid_key=>1, :required=>["age"], :properties=>{}, :allOf=>[{:if=>{:properties=>{}}, :then=>{}}]}
object_schema.errors
# => {:some_invalid_key=>["is not allowed"], :properties=>{:name=>{"another_invalid_key"=>["is not allowed"]}}, :allOf=>{0=>{:then=>{:properties=>{:is_it_luke_skywalker?=>{"yet_another_invalid_key"=>["is not allowed"]}}}}}}

# inspecting the number property
property = object_schema[:properties][:size]
property.class
# => JsonSchema::SchemaMethods::Number
property.required?
# => true
property.key_name
# => "size"
property.meta
# => {
#  :parent=>{:$id=>"http://example.com/example.json", :$schema=>"http://json-schema.org/draft-07/schema#", :type=>"object", :title=>"Test", :some_invalid_key=>1, #:required=>["size"], :properties=>{:empty=>{:$id=>"/properties/empty", :type=>"null", :title=>"empty", :another_invalid_key=>"oh oh", :$schema=>"http://json-#schema.org/draft-07/schema#"}, :size=>{:$id=>"/properties/size", :type=>"number", :title=>"size", :$schema=>"http://json-schema.org/draft-07/schema#"}}, :allOf=>#[]},
#  :path=>[:properties, :size]
#}
```




After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/json_schema_form.
