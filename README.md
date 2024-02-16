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
  - Buildable     (sets transforms used to create recursive tree structures)
- Arrayable     (methods when type `key` equals or contains `array`)
- Booleanable   (methods when type `key` equals or contains `boolean`)
- Nullable      (methods when type `key` equals or contains `null`)
- Numberable    (methods when type `key` equals or contains `number`)
- Objectable    (methods when type `key` equals or contains `object`)
- Stringable    (methods when type `key` equals or contains `string`)

### Example

Lets create a new backing class for a schema using the provided modules

```ruby
# This is how to pre-wired `JSF::Schema` class is created
class MySchema < BaseHash

  include JSF::Core::Schemable
  include JSF::Core::Buildable
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

As you can see, every time a subschema is found a new instance is serialized by using de default transforms in `JSF::Core::Buildable`
It is important to note that the transforms are present ONLY on the following keys:

```ruby
[:additionalProperties, :contains, :definitions, :dependencies, :else, :if, :items, :not, :properties, :then, :allOf, :anyOf, :oneOf]
```

So if you want to add a new schema AFTER instanciation (for example another property in the `properties` key), you must to re-set the whole key
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

#4) set an already transformed value
schema[:properties][:prop4] = MySchema.new({type: 'number'})
schema[:properties][:prop4].class # => MySchema
```

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

If you want to customize how the tree is built, override the `attributes_transform` method provided by `JSF::Core::Buildable`

```ruby
class MySchema2 < MySchema
  def attributes_transform(attribute, *args)
    if attribute == 'if'
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

Keep in mind that all subschemas inside `if` will be instances of `MySchema` because that is it's default `attributes_transform`;

### Methods

- `root_parent`

```ruby
  schema = JSF::Schema.new( {properties: {prop1: {type: 'string'}}, allOf:[{if: {prop1: {const: 'test'}}, then: {properties: {prop2: {type: 'string'}}}}]} )
  schema[:allOf].first[:then][:properties][:prop2].root_parent == schema #=> true
```

### Validations

In addition to this, you can add validations to your objects by using the `JSF::Validations::Validatable` module.
A basic validation example would be this

```ruby
class MySchema < JSF::BaseHash
  include JSF::Core::Schemable
  include JSF::Core::Buildable #required for validations
  include JSF::Validations::Validatable

  def errors(**passthru)
    errors_hash = super
    errors_hash[:$id] = 'id must be present' if self[:$id].nil?
    errors_hash
  end

end

schema = MySchema.new(type: 'array', items: [{type: 'string'}])
schema.errors #=> {"items"=>{0=>{"$id"=>"id must be present"}}, "$id"=>"id must be present"}
```

`passthru` is a hash of options that are passed across all child nodes of the tree.

#### Dry-Schema Validations

By adding the following line to your class, you automatically get default json_schema validations.
`include JSF::Validations::DrySchemaValidated`

## SchemaForm

A `form` is composed of the follow classes:

- `JSF::Forms::Form`
  - `JSF::Forms::ResponseSet`
    - `JSF::Forms::Response`
  - `JSF::Forms::Field::Checkbox`
  - `JSF::Forms::Field::DateInput`
  - `JSF::Forms::Field::FileInput`
  - `JSF::Forms::Field::Geopoints`
  - `JSF::Forms::Field::Markdown`
  - `JSF::Forms::Field::NumberInput`
  - `JSF::Forms::Field::Select`
  - `JSF::Forms::Field::Shared`
  - `JSF::Forms::Field::Slider`
  - `JSF::Forms::Field::Static`
  - `JSF::Forms::Field::Switch`
  - `JSF::Forms::Field::TextInput`

### Form

 ToDo

### Field

 ToDo

### ResponseSet

 ToDo

### Response

`JSF::Forms::Response` is contained by `JSF::Forms::ResponseSet`
 ToDo

## document

- `JSF::Forms::Response`
ToDO

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
