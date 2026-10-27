defmodule ExRss.FeedsFixtures do
  def rss_fixture_path(name), do: Path.join(["test", "support", "fixtures", "rss", name])
  def rss_fixture(name), do: File.read!(rss_fixture_path(name))
end
