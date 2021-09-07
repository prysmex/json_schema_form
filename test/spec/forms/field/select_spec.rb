require 'json_schema_form_test_helper'
require_relative 'methods/base_spec'
require_relative 'methods/response_settable_spec'

class SelectTest < Minitest::Test

  include BaseMethodsTests
  include ResponseSettableTests

end