require "test_helper"

class StrictTypesTest < Minitest::Test
  include TestHelper::SampleClassHooks

  # general for all types
  TestHelper::JSON_SCHEMA_TYPES.each do |type|
    strict_type_module = Object.const_get("JsonSchema::StrictTypes::#{type.capitalize}")

    # define_method "test_strict_#{type}_required_type" do
    #   SampleSchema.include(strict_type_module)
    #   assert_raises(::SuperHash::Exceptions::PropertyError) { SampleSchema.new() }
    # end
    
    define_method "test_strict_#{type}_fails_if_type_not_equals_#{type}" do
      SampleSchema.include(strict_type_module)
      assert_raises(::Dry::Types::ConstraintError) { SampleSchema.new({type: 'whatever'}) }
    end
  
    define_method "test_strict_#{type}_type_may_equal_#{type}" do 
      SampleSchema.include(strict_type_module)
      assert_equal type, SampleSchema.new({type: type})[:type]
    end
  end

  #Array

  #String

  #Boolean

  #Null

  #Number

  #object

end