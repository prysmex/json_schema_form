# frozen_string_literal: true

require 'test_helper'

class CurrentTest < Minitest::Test
  def test_use_cache
    assert_nil JSF::Current.use_cache

    JSF::Current.use_cache = true

    assert_equal true, JSF::Current.use_cache

    JSF::Current.use_cache = false

    assert_equal false, JSF::Current.use_cache
  end
end