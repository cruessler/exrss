defmodule ExRss.UpdateBroadcaster do
  @callback broadcast_update(ExRss.Feed.t()) :: {:ok, nil}
end
