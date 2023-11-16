defmodule ExRss.Crawler.Queue do
  use GenServer

  require Ecto.Query
  require Logger

  @store ExRss.Crawler.Store
  @updater ExRss.Crawler.Updater
  @update_broadcaster ExRss.Crawler.UpdateBroadcaster

  def start_link(opts \\ []) do
    opts =
      opts
      |> Keyword.put_new(:store, @store)
      |> Keyword.put_new(:updater, @updater)
      |> Keyword.put_new(:update_broadcaster, @update_broadcaster)

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
    Logger.info("Handling feed", title: first.title, url: first.url)

    %{ref: ref} = Task.async(opts[:updater], :update, [first])

    # The reference to the worker is saved so the corresponding feed can be
    # reinserted into the queue, should the update fail.
    refs = Map.put(refs, ref, first)

    {:noreply, %{state | feeds: rest, refs: refs}, timeout(rest)}
  end

  # Handle regular success and error cases: Add the feed back to the queue.
  def handle_info({_ref, {:ok, feed}}, %{feeds: feeds, opts: opts} = state) do
    Logger.info("Updated feed", title: feed.title, url: feed.url)

    new_feed = opts[:store].update_on_success!(feed)

    Task.Supervisor.start_child(
      ExRss.TaskSupervisor,
      opts[:update_broadcaster],
      :broadcast_update,
      [new_feed]
    )

    new_queue = insert(feeds, new_feed)

    {:noreply, %{state | feeds: new_queue}, timeout(new_queue)}
  end

  def handle_info({ref, {:error, error}}, %{feeds: feeds, refs: refs, opts: opts} = state) do
    feed = Map.get(refs, ref)

    Logger.error("Error updating feed", title: feed.title, url: feed.url, error: error)

    new_feed = opts[:store].update_on_error!(feed)

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
  def handle_info({:DOWN, ref, :process, _, _}, %{feeds: feeds, refs: refs, opts: opts} = state) do
    {feed, refs} = Map.pop(refs, ref)

    Logger.error("Uncaught error while updating feed", title: feed.title, url: feed.url)

    new_feed = opts[:store].update_on_error!(feed)

    new_queue = insert(feeds, new_feed)

    {:noreply, %{state | feeds: new_queue, refs: refs}, timeout(new_queue)}
  end

  def handle_info(_, state) do
    {:noreply, state, timeout(state[:feeds])}
  end

  def handle_cast({:add_feed, feed}, %{feeds: feeds} = state) do
    Logger.info("Adding feed", title: feed.title, url: feed.url)

    new_queue = insert(feeds, feed)

    {:noreply, %{state | feeds: new_queue}, timeout(new_queue)}
  end

  def handle_cast({:remove_feed, feed}, %{feeds: feeds} = state) do
    Logger.info("Removing feed", title: feed.title, url: feed.url)

    new_queue = remove(feeds, feed)

    {:noreply, %{state | feeds: new_queue}, timeout(new_queue)}
  end

  def insert(queue, feed) do
    [feed | queue]
    |> Enum.sort(fn a, b ->
      Timex.compare(a.next_update_at, b.next_update_at) == -1
    end)
  end

  def remove(queue, feed) do
    queue
    |> Enum.reject(fn f -> f.id == feed.id end)
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
