defmodule ExRss.Crawler.QueueTest do
  use ExUnit.Case, async: true

  alias ExRss.Crawler.Queue
  alias ExRss.Repo

  defmodule TestStore do
    def load(), do: []
  end

  defmodule TestUpdater do
    def update(feed) do
      send feed.pid, :update
    end
  end

  setup do
    # Explicitly get a connection before each test
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  test "timeout" do
    assert Queue.timeout([]) == :infinity
    assert Queue.timeout([%{next_update_at: nil}]) == 0

    duration = Timex.Duration.from_milliseconds(15_000)
    soon = DateTime.utc_now |> Timex.add(duration)
    assert_in_delta Queue.timeout([%{next_update_at: soon}]), 15_000, 100
  end

  test "sends message to updater" do
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    {:ok, pid} =
      Queue.start_link(store: TestStore, updater: TestUpdater)

    feed = %{title: "Test feed", next_update_at: nil, pid: self()}

    GenServer.cast pid, {:add_feed, feed}

    assert_receive :update
  end
end
