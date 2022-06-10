require_relative "test_helper"

class AnnotationsTest < ActionDispatch::IntegrationTest
  def test_line_chart_annotations
    run_query "SELECT NOW(), 1"
    assert_match "line_annotation", response.body
    assert_match "box_annotation", response.body
  end

  def test_other_chart_no_annotations
    run_query "SELECT 'Label' AS label, 1"
    refute_match "line_annotation", response.body
    refute_match "box_annotation", response.body
  end
end
