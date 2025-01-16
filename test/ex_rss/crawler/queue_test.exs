defmodule ExRss.Crawler.QueueTest do
  use ExUnit.Case, async: true

  alias ExRss.Crawler.Queue
  alias ExRss.Repo

  defmodule TestStore do
    def load(), do: []

    def update_on_success!(feed) do
      send(feed.pid, :update_on_success)

      feed
    end
  end

  defmodule TestUpdater do
    def update(feed) do
      send(feed.pid, :update)
    end
  end

  defmodule TestBroadcaster do
    def broadcast_update(feed) do
      send(feed.pid, :broadcast_update)
    end
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    :ok
  end

  test "timeout" do
    assert Queue.timeout([]) == :infinity
    assert Queue.timeout([%{next_update_at: nil}]) == 0

    duration = Timex.Duration.from_milliseconds(15_000)
    soon = DateTime.utc_now() |> Timex.add(duration)
    assert_in_delta Queue.timeout([%{next_update_at: soon}]), 15_000, 200
  end

  test "sends message without next_update_at to updater immediately" do
    {:ok, pid} = Queue.start_link(store: TestStore, updater: TestUpdater)

    feed = %{title: "Test feed", url: "http://example.com", next_update_at: nil, pid: self()}

    GenServer.cast(pid, {:add_feed, feed})

    assert_receive :update
  end

  test "sends message to updater with delay" do
    {:ok, pid} = Queue.start_link(store: TestStore, updater: TestUpdater)

    next_update_at = Timex.shift(DateTime.utc_now(), milliseconds: 20)

    feed = %{
      title: "Test feed",
      url: "http://example.com",
      next_update_at: next_update_at,
      pid: self()
    }

    GenServer.cast(pid, {:add_feed, feed})

    assert_receive :update, 200
  end

  test "sends message to update_broadcaster" do
    feed = %{title: "Test feed", url: "http://example.com", next_update_at: nil, pid: self()}
    feeds = []

    opts = %{
      store: TestStore,
      update_broadcaster: TestBroadcaster
    }

    state = %{feeds: feeds, opts: opts}

    Queue.handle_info({nil, {:ok, feed}}, state)

    assert_receive :update_on_success
    assert_receive :broadcast_update
  end
end
