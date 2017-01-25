defmodule ExRss.Crawler.Queue do
  use GenServer

  require Ecto.Query
  require Logger

  alias Ecto.Changeset
  alias ExRss.Feed
  alias ExRss.Repo

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, Keyword.put(opts, :name, __MODULE__))
  end

  def init(:ok) do
    feeds =
      Ecto.Query.from(Feed, order_by: [asc: :next_update_at])
      |> Repo.all
      |> Enum.map(fn
        %{next_update_at: nil} = feed -> %{feed | next_update_at: DateTime.utc_now}
        feed -> feed
      end)

    {:ok, {feeds, %{}}, timeout(feeds)}
  end

  def handle_info(:timeout, {[first|rest], refs}) do
    Logger.debug "Handling feed #{first.title}"

    %{ref: ref} = Task.async(ExRss.Crawler.Updater, :update, [first])

    # The reference to the worker is saved so the corresponding feed can be
    # reinserted into the queue, should the update fail.
    refs = Map.put(refs, ref, first)

    {:noreply, {rest, refs}, timeout(rest)}
  end

  # Handle regular success and error cases: Add the feed back to the queue.
  def handle_info({_ref, {:ok, feed}}, {feeds, refs}) do
    new_feed =
      feed
      |> Changeset.change
      |> Feed.schedule_update_on_success
      |> Repo.update!

    new_queue = insert(feeds, new_feed)

    {:noreply, {new_queue, refs}, timeout(new_queue)}
  end
  def handle_info({_ref, {:error, feed}}, {feeds, refs}) do
    new_feed =
      feed
      |> Changeset.change
      |> Feed.schedule_update_on_error
      |> Repo.update!

    new_queue = insert(feeds, new_feed)

    {:noreply, {new_queue, refs}, timeout(new_queue)}
  end
  # Handle regular child exit. The feed has already been reinserted by one of
  # the upper function clauses, so only the reference to the worker has to be
  # removed.
  def handle_info({:DOWN, ref, :process, _, :normal}, {feeds, refs}) do
    {_, refs} = Map.pop(refs, ref)

    {:noreply, {feeds, refs}, timeout(feeds)}
  end
  # Whenever a child exits for a reason other than :normal, the reference to
  # that process is removed and the corresponding feed is reinserted into the
  # queue.
  def handle_info({:DOWN, ref, :process, _, _}, {feeds, refs}) do
    {feed, refs} = Map.pop(refs, ref)

    new_feed =
      feed
      |> Changeset.change
      |> Feed.schedule_update_on_error
      |> Repo.update!

    new_queue = insert(feeds, new_feed)

    {:noreply, {new_queue, refs}, timeout(new_queue)}
  end

  def handle_info(_, {feeds, refs}) do
    {:noreply, {feeds, refs}, timeout(feeds)}
  end

  def insert(queue, feed) do
    queue ++ [feed]
    |> Enum.sort(fn a, b ->
      Timex.compare(a.next_update_at, b.next_update_at) == -1
    end)
  end

  def timeout([%{next_update_at: nil}|_]) do
    0
  end
  def timeout([first|_]) do
    first.next_update_at
    |> Timex.diff(DateTime.utc_now, :milliseconds)
    |> max(0)
  end
  def timeout([]) do
    :infinity
  end
end
