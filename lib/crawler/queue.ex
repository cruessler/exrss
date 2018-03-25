defmodule ExRss.Crawler.Queue do
  use GenServer

  require Ecto.Query
  require Logger

  alias Ecto.Changeset
  alias ExRss.Feed
  alias ExRss.Repo

  @store ExRss.Crawler.Store
  @updater ExRss.Crawler.Updater

  def start_link(opts \\ []) do
    opts =
      opts
      |> Keyword.put_new(:store, @store)
      |> Keyword.put_new(:updater, @updater)

    state = %{opts: opts, feeds: [], refs: %{}}

    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(%{opts: opts} = state) do
    feeds = opts[:store].load()

    state =
      state
      |> Map.put(:feeds, feeds)

    {:ok, state, timeout(feeds)}
  end

  def handle_info(:timeout, %{feeds: [first | rest], refs: refs, opts: opts} = state) do
    Logger.info("Handling feed #{first.title} (#{first.url})")

    %{ref: ref} = Task.async(opts[:updater], :update, [first])

    # The reference to the worker is saved so the corresponding feed can be
    # reinserted into the queue, should the update fail.
    refs = Map.put(refs, ref, first)

    {:noreply, %{state | feeds: rest, refs: refs}, timeout(rest)}
  end

  # Handle regular success and error cases: Add the feed back to the queue.
  def handle_info({_ref, {:ok, feed}}, %{feeds: feeds} = state) do
    Logger.info("Updated feed #{feed.title}")

    new_feed =
      feed
      |> Changeset.change()
      |> Feed.schedule_update_on_success()
      |> Repo.update!()

    new_queue = insert(feeds, new_feed)

    {:noreply, %{state | feeds: new_queue}, timeout(new_queue)}
  end

  def handle_info({_ref, {:error, feed}}, %{feeds: feeds} = state) do
    Logger.info("Error while updating #{feed.title}")

    new_feed =
      feed
      |> Changeset.change()
      |> Feed.schedule_update_on_error()
      |> Repo.update!()

    new_queue = insert(feeds, new_feed)

    {:noreply, %{state | feeds: new_queue}, timeout(new_queue)}
  end

  # Handle regular child exit. The feed has already been reinserted by one of
  # the upper function clauses, so only the reference to the worker has to be
  # removed.
  def handle_info({:DOWN, ref, :process, _, :normal}, %{refs: refs} = state) do
    {_, refs} = Map.pop(refs, ref)

    {:noreply, %{state | refs: refs}, timeout(state[:feeds])}
  end

  # Whenever a child exits for a reason other than :normal, the reference to
  # that process is removed and the corresponding feed is reinserted into the
  # queue.
  def handle_info({:DOWN, ref, :process, _, _}, %{feeds: feeds, refs: refs} = state) do
    {feed, refs} = Map.pop(refs, ref)

    Logger.info("Uncaught error while updating #{feed.title}")

    new_feed =
      feed
      |> Changeset.change()
      |> Feed.schedule_update_on_error()
      |> Repo.update!()

    new_queue = insert(feeds, new_feed)

    {:noreply, %{state | feeds: new_queue, refs: refs}, timeout(new_queue)}
  end

  def handle_info(_, state) do
    {:noreply, state, timeout(state[:feeds])}
  end

  def handle_cast({:add_feed, feed}, %{feeds: feeds} = state) do
    Logger.info("Adding feed #{feed.title} (#{feed.url})")

    new_queue = insert(feeds, feed)

    {:noreply, %{state | feeds: new_queue}, timeout(new_queue)}
  end

  def insert(queue, feed) do
    [feed | queue]
    |> Enum.sort(fn a, b ->
      Timex.compare(a.next_update_at, b.next_update_at) == -1
    end)
  end

  def timeout([%{next_update_at: nil} | _]) do
    0
  end

  def timeout([first | _]) do
    first.next_update_at
    |> Timex.diff(DateTime.utc_now(), :milliseconds)
    |> max(0)
  end

  def timeout([]) do
    :infinity
  end
end
