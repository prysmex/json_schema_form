# JsonSchemaForm

JsonSchemaForm is divided into two parts:
1) JsonSchema, provides a simple and extensible API to create backing classes for json_schema hashes [json_schema](https://json-schema.org/) so you don't mess around with POROs.
2) SchemaForm, provides build-in classes that provide form-like functionality that are based on json_schema. This classes are created using `JsonSchema`

To do this, this gem is powered by [superhash](https://github.com/prysmex/super_hash) so you might want to get familiar with it before starting.
Default validations are powered by Dry::Schema [dry-schema](https://dry-rb.org/gems/dry-schema)

## JsonSchema

### Modules

This is the backbone and provides multiple ruby `Module`s that are used to easily create a backing class for a json_schema object
- Schemable     (base methods are in a module yo avoid creatinga Base class)
- - Buildable     (sets transforms used to create recursive tree structures)
- Arrayable     (methods when type `key` equals or contains `array`)
- Booleanable   (methods when type `key` equals or contains `boolean`)
- Nullable      (methods when type `key` equals or contains `null`)
- Numberable    (methods when type `key` equals or contains `number`)
- Objectable    (methods when type `key` equals or contains `object`)
- Stringable    (methods when type `key` equals or contains `string`)

### Example

Lets create a new backing class for a schema using the provided modules
```ruby
class MySchema < ::SuperHash::Hasher

  include JsonSchema::SchemaMethods::Schemable
  include JsonSchema::SchemaMethods::Buildable
  include JsonSchema::SchemaMethods::Objectable
  include JsonSchema::SchemaMethods::Stringable
  include JsonSchema::SchemaMethods::Numberable
  include JsonSchema::SchemaMethods::Booleanable
  include JsonSchema::SchemaMethods::Arrayable
  include JsonSchema::SchemaMethods::Nullable

end

schema = MySchema.new({properties: {prop1: {type: 'string'}}})
schema.class #=> MySchema
schema[:properties][:prop1].class #=> MySchema
```
As you can see, every time a subschema is found a new instance is serialized by using de default transforms in `JsonSchema::SchemaMethods::Buildable`
It is important to not that the transforms are present on the following keys:
```ruby
[:additionalProperties, :contains, :definitions, :dependencies, :else, :if, :items, :not, :properties, :then, :allOf, :anyOf, :oneOf]
```
So if you want to add a new schema after instanciation (for example another property in the `properties` key), you need to re-set the whole key
or set an already transformed value. Here is a small demostration:
```ruby
#WRONG
schema = MySchema.new({properties: {}})
schema[:properties][:prop1] = {type: 'number'}
schema[:properties][:prop1].class # => Hash, not MySchema because transforms where not triggered!

#CORRECT
#1) set all values before instanciation
hash = {properties: {prop:1 {type: 'null'}}}
schema = MySchema.new(hash)
schema[:properties][:prop1].class # => MySchema

#2) set properties key
schema[:properties] = schema[:properties].merge({prop2: {type: 'number'}})
schema[:properties][:prop2].class # => MySchema

#3) use provided method
schema.add_property(:prop3, {type: 'number'})
schema[:properties][:prop3].class # => MySchema
```

This is how to pre-wired `JsonSchema::Schema` class is created

### Meta
The schema's `meta` method contains helpful data
```ruby
# traverse upwards in the tree
schema[:properties][:prop1].meta[:parent] #=> {:properties=>{:prop1=>{:type=>"string"}}}
#path
schema[:properties][:prop1].meta[:path] #=> [:properties, :prop1]
#checking if is subschema
schema[:properties][:prop1].meta[:is_subschema] #=> true
```

### Custom tree

If you want to customize how the tree is built, override the `builder` method provided by `JsonSchema::SchemaMethods::Buildable`
```ruby
class MySchema2 < MySchema
  def builder(attribute, *args)
    if attribute == :if
      MySchema.new(*args)
    else
      super(attribute, *args) #defaults to own class
    end
  end
end
schema = MySchema2.new({if: {type: 'string'}, then: {enum: ['option_1']}})
schema[:if].class #=> MySchema
schema[:then].class #=> MySchema2
```
Keep in mind that all subschemas inside `if` will be instances of `MySchema` because that is it's default builder;

### Methods

- `root_parent`
```ruby
  schema = JsonSchema::Schema.new( {properties: {prop1: {type: 'string'}}, allOf:[{if: {prop1: {const: 'test'}}, then: {properties: {prop2: {type: 'string'}}}}]} )
  schema[:allOf].first[:then][:properties][:prop2].root_parent == schema #=> true
```

### Validations
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

`passthru` is a hash of options that are passed across all child nodes of the tree.

#### Dry-Schema Validations

By adding the following line to your class, you automatically get default json_schema validations.
`include JsonSchema::Validations::DrySchemaValidatable`

## SchemaForm

A `form` is composed of the follow classes:
- `SchemaForm::Form`
  - `SchemaForm::ResponseSet`
    - `SchemaForm::Response`
  - `SchemaForm::Field::Checkbox`
  - `SchemaForm::Field::Component`
  - `SchemaForm::Field::DateInput`
  - `SchemaForm::Field::Header`
  - `SchemaForm::Field::Info`
  - `SchemaForm::Field::NumberInput`
  - `SchemaForm::Field::Select`
  - `SchemaForm::Field::Slider`
  - `SchemaForm::Field::Static`
  - `SchemaForm::Field::Switch`
  - `SchemaForm::Field::TextInput`

### Form:
 ToDo
 
### Field:
 ToDo
### ResponseSet:
 ToDo
### Response:
`SchemaForm::Response` is contained by `SchemaForm::ResponseSet`
 ToDo

### Field:
 ToDo
 
## document:
Backing class used by Prysmex for the 'raw data' that is created when a form is filled.
 - `JsonSchemaForm::Document::Document` main class for storing 'raw data'
 - `JsonSchemaForm::Document::Extras` used by `Inspection` only
 - `JsonSchemaForm::Document::Meta` used by `Inspection` only

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




After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/json_schema_form.
