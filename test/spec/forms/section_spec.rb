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

  def test_valid_for_locale
    instance = JSF::Forms::Section.new(
      JSF::Forms::FormBuilder.example('section')
    )

    # empty hash
    instance[:items] = {}
    assert_equal true, instance.valid_for_locale?

    # valid form
    JSF::Forms::FormBuilder.build(instance[:items]) do
      append_property(:switch_1, example('switch'))
    end
    assert_equal true, instance.valid_for_locale?

    # invalid form
    instance[:items].get_property('switch_1').set_label_for_locale(nil)
    assert_equal false, instance.valid_for_locale?

    # missing key
    instance.delete(:items)
    assert_equal true, instance.valid_for_locale?
  end

end