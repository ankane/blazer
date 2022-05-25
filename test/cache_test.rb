require_relative "test_helper"

class CacheTest < ActionDispatch::IntegrationTest
  def setup
    Rails.cache.clear
  end

  def test_all
    with_caching({"mode" => "all"}) do
      run_query "SELECT 1"
      refute_match "Cached", response.body
      run_query "SELECT 1"
      assert_match "Cached", response.body
    end
  end

  def test_slow_under_threshold
    with_caching({"mode" => "slow"}) do
      run_query "SELECT 1"
      refute_match "Cached", response.body
      run_query "SELECT 1"
      refute_match "Cached", response.body
    end
  end

  def test_slow_over_threshold
    with_caching({"mode" => "slow", "slow_threshold" => 0.01}) do
      run_query "SELECT pg_sleep(0.01)::text"
      refute_match "Cached", response.body
      run_query "SELECT pg_sleep(0.01)::text"
      assert_match "Cached", response.body
    end
  end

  def test_variables
    with_caching({"mode" => "all"}) do
      run_query "SELECT {str_var}, {int_var}", variables: {str_var: "hello", int_var: 1}
      assert_match "hello", response.body
    end
  end

  private

  def with_caching(value)
    Blazer.data_sources["main"].stub(:cache, value) do
      yield
    end
  end
end
