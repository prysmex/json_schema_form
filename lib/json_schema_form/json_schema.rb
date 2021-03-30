#schema methods
require_relative 'json_schema/schema_methods/schemable'
require_relative 'json_schema/schema_methods/arrayable'
require_relative 'json_schema/schema_methods/booleanable'
require_relative 'json_schema/schema_methods/nullable'
require_relative 'json_schema/schema_methods/numberable'
require_relative 'json_schema/schema_methods/objectable'
require_relative 'json_schema/schema_methods/stringable'
require_relative 'json_schema/schema_methods/buildable'

#validations
require_relative 'json_schema/validations/validatable'
require_relative 'json_schema/validations/dry_schema_validatable'

require_relative 'json_schema/schema'
require_relative 'json_schema/strict_types'