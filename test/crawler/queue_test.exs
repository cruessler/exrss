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

    # Allow the queue to access the tests’ db connection
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    :ok
  end

  test "timeout" do
    assert Queue.timeout([]) == :infinity
    assert Queue.timeout([%{next_update_at: nil}]) == 0

    duration = Timex.Duration.from_milliseconds(15_000)
    soon = DateTime.utc_now |> Timex.add(duration)
    assert_in_delta Queue.timeout([%{next_update_at: soon}]), 15_000, 100
  end

  test "sends message without next_update_at to updater immediately" do
    {:ok, pid} =
      Queue.start_link(store: TestStore, updater: TestUpdater)

    feed = %{title: "Test feed", next_update_at: nil, pid: self()}

    GenServer.cast pid, {:add_feed, feed}

    assert_receive :update
  end

  test "sends message to updater with delay" do
    {:ok, pid} =
      Queue.start_link(store: TestStore, updater: TestUpdater)

    next_update_at = Timex.shift(DateTime.utc_now, milliseconds: 200)

    feed = %{title: "Test feed", next_update_at: next_update_at, pid: self()}

    GenServer.cast pid, {:add_feed, feed}

    assert_receive :update, 200
  end
end
