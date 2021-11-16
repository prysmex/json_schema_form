require 'test_helper'

class SectionTest < Minitest::Test

  ##################
  ###VALIDATIONS####
  ##################

  ##############
  ###METHODS####
  ##############

  def test_scored?
    instance = JSF::Forms::Section.new(
      JSF::Forms::FormBuilder.example('section')
    )

    assert_equal false, instance.scored?

    instance['items'] = JSF::Forms::FormBuilder.build do
      append_property(:switch, example('switch'))
    end

    assert_equal true, instance.scored?
  end

end