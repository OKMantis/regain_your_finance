require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  # ── progress_bar_color ──────────────────────────────────────────────────────

  test "progress_bar_color returns nil when target_cents is nil" do
    assert_nil progress_bar_color(500, nil)
  end

  test "progress_bar_color returns nil when target_cents is zero" do
    assert_nil progress_bar_color(500, 0)
  end

  test "progress_bar_color returns emerald when under 80 percent" do
    assert_equal "bg-emerald-500", progress_bar_color(79, 100)
  end

  test "progress_bar_color returns emerald at exactly 0 percent" do
    assert_equal "bg-emerald-500", progress_bar_color(0, 100)
  end

  test "progress_bar_color returns amber at exactly 80 percent" do
    assert_equal "bg-amber-500", progress_bar_color(80, 100)
  end

  test "progress_bar_color returns amber between 80 and 99 percent" do
    assert_equal "bg-amber-500", progress_bar_color(99, 100)
  end

  test "progress_bar_color returns red at exactly 100 percent" do
    assert_equal "bg-red-500", progress_bar_color(100, 100)
  end

  test "progress_bar_color returns red when over 100 percent" do
    assert_equal "bg-red-500", progress_bar_color(150, 100)
  end

  # ── progress_bar_width ─────────────────────────────────────────────────────

  test "progress_bar_width returns 0% when target_cents is nil" do
    assert_equal "0%", progress_bar_width(500, nil)
  end

  test "progress_bar_width returns 0% when target_cents is zero" do
    assert_equal "0%", progress_bar_width(500, 0)
  end

  test "progress_bar_width returns 0% when spent is zero" do
    assert_equal "0.0%", progress_bar_width(0, 1000)
  end

  test "progress_bar_width returns correct percentage for partial spend" do
    assert_equal "50.0%", progress_bar_width(500, 1000)
  end

  test "progress_bar_width returns 100% when exactly at target" do
    assert_equal "100.0%", progress_bar_width(1000, 1000)
  end

  test "progress_bar_width is capped at 100% when over target" do
    # min(200.0, 100) returns the Integer 100; Integer#round(1) returns an Integer
    # so the formatted result is "100%" not "100.0%"
    result = progress_bar_width(2000, 1000)
    assert result.start_with?("100"), "Expected width to be capped at 100, got: #{result}"
    assert result.end_with?("%")
  end

  test "progress_bar_width rounds to one decimal place" do
    # 1/3 of 300 = 33.3...%
    result = progress_bar_width(100, 300)
    assert_equal "33.3%", result
  end
end
