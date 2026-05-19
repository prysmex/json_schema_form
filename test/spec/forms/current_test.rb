# frozen_string_literal: true

require 'test_helper'

class CurrentTest < Minitest::Test
  def setup
    JSF::Current.reset
  end

  def teardown
    JSF::Current.reset
  end

  def test_use_cache
    assert_equal false, JSF::Current.use_cache

    JSF::Current.use_cache = true

    assert_equal true, JSF::Current.use_cache

    JSF::Current.use_cache = false

    assert_equal false, JSF::Current.use_cache
  end
end