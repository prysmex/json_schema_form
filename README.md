# JsonSchemaForm

This gem is powered by [superhash](https://github.com/prysmex/super_hash) so you might need to get familiar with it before starting.

Validations are powered by Dry::Schema [dry-schema](https://dry-rb.org/gems/dry-schema)

JsonSchemaForm gem is designed to contain the backing classes for form definitions that are based on json schema standard [json_schema](https://json-schema.org/). There are some differences between the standard schemas and the ones defined by JsonSchemaForm::Form, mainly to support:
 - Response sets
 - Display properties
 - versioning and version migration
 
The classes can be divided into the following 'modules':

### json_schema:
Can be used to back plain and standard [json_schema](https://json-schema.org/) schemas. They all inherit from `JsonSchemaForm::SchemaMethods::Base`
 - `JsonSchemaForm::SchemaMethods::Array`
 - `JsonSchemaForm::SchemaMethods::Boolean`
 - `JsonSchemaForm::SchemaMethods::Null`
 - `JsonSchemaForm::SchemaMethods::Number`
 - `JsonSchemaForm::SchemaMethods::String`
 - `JsonSchemaForm::SchemaMethods::Object`
    
### form/field:
These classes are used by JsonSchemaForm::Form to define its properties or 'fields'
| Name                                  | Parent class                          |
| ------------------------------------- |:-------------------------------------:|
|`JsonSchemaForm::Field::Checkbox`      |`< JsonSchemaForm::SchemaMethods::Array`|
|`JsonSchemaForm::Field::DateInput`     |`< JsonSchemaForm::SchemaMethods::String`|
|`JsonSchemaForm::Field::Header`        |`< JsonSchemaForm::SchemaMethods::Null`|
|`JsonSchemaForm::Field::Info`          |`< JsonSchemaForm::SchemaMethods::Null`|
|`JsonSchemaForm::Field::NumberInput`   |`< JsonSchemaForm::SchemaMethods::Number`|
|`JsonSchemaForm::Field::Select`        |`< JsonSchemaForm::SchemaMethods::String`|
|`JsonSchemaForm::Field::Slider`        |`< JsonSchemaForm::SchemaMethods::Number`|
|`JsonSchemaForm::Field::Static`        |`< JsonSchemaForm::SchemaMethods::Null`|
|`JsonSchemaForm::Field::Switch`        |`< JsonSchemaForm::SchemaMethods::Boolean`|
|`JsonSchemaForm::Field::TextInput`     |`< JsonSchemaForm::SchemaMethods::String`|
|`JsonSchemaForm::Form`                 |`< JsonSchemaForm::SchemaMethods::Object`|

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

These methods are available in all `JsonSchemaForm::SchemaMethods::*` classes:
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

In addition to the previous methods, the `JsonSchemaForm::SchemaMethods::Object` class has the following methods:
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
number_schema = JsonSchemaForm::SchemaMethods::Number.new({
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
object_schema = JsonSchemaForm::SchemaMethods::Object.new({
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
# => JsonSchemaForm::SchemaMethods::Number
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

### form/field:

#### TextInput

Although fields are most likely to always be found inside a JsonSchemaForm definition, here is an example of a standalone text_input object

```ruby
text_input = JsonSchemaForm::Field::TextInput.new(
  {
    "$id": "/properties/text_area9302",
    "title": "text_area9302",
    "type": "string",
    "some_invalid_property": 1,
    "displayProperties": {
      "pictures": [],
      "i18n": {
        "label": {
          "es": "Area de texto",
          "en": "Text area"
        }
      },
      "visibility": {
        "label": true
      },
      "textarea": true,
      "sort": 4,
      "hidden": false
    },
    "$schema": "http://json-schema.org/draft-07/schema#"
  }
)

text_input.errors
# => {:some_invalid_property=>["is not allowed"]}
```

```ruby
JsonSchemaForm::Form.new(
  {
    "$id": "http://example.com/example.json",
    "$schema": "http://json-schema.org/draft-07/schema#",
    "title": "",
    "type": "object",
    "schemaFormVersion": "1.0.0",
    "required": [
      "text_area9302"
    ],
    "properties": {
      "text_area9302": {
        "$id": "/properties/text_area9302",
        "title": "text_area9302",
        "type": "string",
        "displayProperties": {
          "pictures": [],
          "i18n": {
            "label": {
              "es": "Area de texto",
              "en": "Text area"
            }
          },
          "visibility": {
            "label": true
          },
          "textarea": true,
          "sort": 4,
          "hidden": false
        },
        "$schema": "http://json-schema.org/draft-07/schema#"
      },
      "seleccion_anidados_requerido4608": {
        "$id": "/properties/seleccion_anidados_requerido4608",
        "title": "seleccion_anidados_requerido4608",
        "type": "string",
        "displayProperties": {
          "pictures": [],
          "i18n": {
            "label": {
              "es": "Seleccion anidados requeridos",
              "en": "Nested required"
            }
          },
          "visibility": {
            "label": true
          },
          "sort": 33,
          "hidden": false
        },
        "$schema": "http://json-schema.org/draft-07/schema#",
        "responseSetId": "10b4b02b-5afe-4bfc-98fe-f975b4513df8"
      }
    },
    "allOf": [
      {
        "if": {
          "properties": {
            "seleccion_anidados_requerido4608": {
              "const": "option8663"
            }
          }
        },
        "then": {
          "properties": {
            "sub_campo_11542": {
              "$id": "/properties/sub_campo_11542",
              "title": "sub_campo_11542",
              "type": "string",
              "displayProperties": {
                "pictures": [],
                "i18n": {
                  "label": {
                    "es": "Sub campo 1",
                    "en": "Sub field 1"
                  }
                },
                "visibility": {
                  "label": true
                },
                "sort": 0,
                "hidden": false
              },
              "$schema": "http://json-schema.org/draft-07/schema#",
              "responseSetId": "64d34cdc-be7b-49ca-9c14-7705c5f06e5d"
            }
          },
          "allOf": [
            {
              "if": {
                "properties": {
                  "sub_campo_11542": {
                    "const": "option7436"
                  }
                }
              },
              "then": {
                "properties": {
                  "sub_field_26149": {
                    "$id": "/properties/sub_field_26149",
                    "title": "sub_field_26149",
                    "type": "boolean",
                    "displayProperties": {
                      "pictures": [],
                      "i18n": {
                        "label": {
                          "es": "Sub campo 2",
                          "en": "Sub field 2"
                        },
                        "trueLabel": {
                          "en": "Show sub-field",
                          "es": "Mostrar sub-campo"
                        },
                        "falseLabel": {
                          "en": "Hide sub-field",
                          "es": "Esconder sub-campo"
                        }
                      },
                      "visibility": {
                        "label": true
                      },
                      "useToggle": true,
                      "sort": 0,
                      "hidden": false
                    },
                    "default": false,
                    "$schema": "http://json-schema.org/draft-07/schema#"
                  }
                },
                "allOf": [
                  {
                    "if": {
                      "properties": {
                        "sub_field_26149": {
                          "const": true
                        }
                      }
                    },
                    "then": {
                      "properties": {
                        "hola6972": {
                          "$id": "/properties/hola6972",
                          "title": "hola6972",
                          "type": "null",
                          "displayProperties": {
                            "pictures": [],
                            "i18n": {
                              "label": {
                                "es": "Hola!",
                                "en": "Hello"
                              }
                            },
                            "visibility": {
                              "label": true
                            },
                            "kind": "neutral",
                            "useInfo": true,
                            "icon": "info",
                            "sort": 0,
                            "hidden": false
                          },
                          "$schema": "http://json-schema.org/draft-07/schema#"
                        }
                      },
                      "$id": "http://example.com/example.json",
                      "$schema": "http://json-schema.org/draft-07/schema#",
                      "required": [],
                      "allOf": []
                    }
                  }
                ],
                "$id": "http://example.com/example.json",
                "$schema": "http://json-schema.org/draft-07/schema#",
                "required": []
              }
            }
          ],
          "required": [
            "sub_campo_11542"
          ],
          "$id": "http://example.com/example.json",
          "$schema": "http://json-schema.org/draft-07/schema#"
        }
      }
    ],
    "responseSets": {
      "10b4b02b-5afe-4bfc-98fe-f975b4513df8": {
        "responses": [
          {
            "value": "option8663",
            "enableScore": true,
            "score": null,
            "failed": false,
            "displayProperties": {
              "i18n": {
                "en": "Show sub-field",
                "es": "Mostrar sub-campo"
              },
              "color": null
            }
          },
          {
            "value": "option3147",
            "enableScore": true,
            "score": null,
            "failed": false,
            "displayProperties": {
              "i18n": {
                "en": "Hide sub-field",
                "es": "Esconder sub-campo"
              },
              "color": null
            }
          }
        ],
        "id": "10b4b02b-5afe-4bfc-98fe-f975b4513df8"
      }
    }
  }
)
```


### document:
    
### response:

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/json_schema_form.
