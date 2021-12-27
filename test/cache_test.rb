require_relative "test_helper"

class CacheTest < ActionDispatch::IntegrationTest
  def setup
    Rails.cache.clear
  end

  def test_all
    Blazer.data_sources["main"].stub(:cache, {"mode" => "all"}) do
      run_query "SELECT 1"
      refute_match "Cached", response.body
      run_query "SELECT 1"
      assert_match "Cached", response.body
    end
  end

  def test_slow_under_threshold
    Blazer.data_sources["main"].stub(:cache, {"mode" => "slow"}) do
      run_query "SELECT 1"
      refute_match "Cached", response.body
      run_query "SELECT 1"
      refute_match "Cached", response.body
    end
  end

  def test_slow_over_threshold
    Blazer.data_sources["main"].stub(:cache, {"mode" => "slow", "slow_threshold" => 0.01}) do
      run_query "SELECT pg_sleep(0.01)::text"
      refute_match "Cached", response.body
      run_query "SELECT pg_sleep(0.01)::text"
      assert_match "Cached", response.body
    end
  end
end
