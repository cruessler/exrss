defmodule ExRss.Crawler.Queue do
  use GenServer

  require Logger

  alias ExRss.Feed
  alias ExRss.FeedUpdater
  alias ExRss.Repo

  @timeout 600_000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, Keyword.put(opts, :name, __MODULE__))
  end

  def init(:ok) do
    feeds = Repo.all(Feed) |> Enum.shuffle

    {:ok, {feeds, %{}}, 0}
  end

  def handle_info(:timeout, {[first|rest], refs}) do
    Logger.debug "Handling feed #{first.title}"

    %{ref: ref} = Task.async(ExRss.Crawler.Updater, :update, [first])

    # The reference to the worker is saved so the corresponding feed can be
    # reinserted into the queue, should the update fail.
    refs = Map.put(refs, ref, first)

    {:noreply, {rest, refs}, @timeout}
  end

  # Handle regular success and error cases: Add the feed back to the queue.
  def handle_info({ref, {:ok, feed}}, {feeds, refs}) do
    {:noreply, {feeds ++ [feed], refs}, @timeout}
  end
  def handle_info({ref, {:error, feed}}, {feeds, refs}) do
    {:noreply, {feeds ++ [feed], refs}, @timeout}
  end
  # Handle regular child exit. The feed has already been reinserted by one of
  # the upper function clauses, so only the reference to the worker has to be
  # removed.
  def handle_info({:DOWN, ref, :process, _, :normal}, {feeds, refs}) do
    {_, refs} = Map.pop(refs, ref)

    {:noreply, {feeds, refs}, @timeout}
  end
  # Whenever a child exits for a reason other than :normal, the reference to
  # that process is removed and the corresponding feed is reinserted into the
  # queue.
  def handle_info({:DOWN, ref, :process, _, _}, {feeds, refs}) do
    {feed, refs} = Map.pop(refs, ref)

    {:noreply, {feeds ++ [feed], refs}, @timeout}
  end

  def handle_info(_, state) do
    {:noreply, state, @timeout}
  end
end
