defmodule ExRssWeb.UserChannel do
  use Phoenix.Channel

  alias Phoenix.Socket.Broadcast

  def join("user:self", _params, socket) do
    user_id = socket.assigns.user_id

    if ExRssWeb.Endpoint.subscribe("user:#{user_id}") == :ok do
      {:ok, socket}
    else
      {:error, %{reason: "could not subscribe"}}
    end
  end

  def join("user:" <> user_id, _params, socket) do
    if user_id == socket.assigns.user_id do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info(%Broadcast{topic: "user:" <> user_id, event: event, payload: payload}, socket) do
    if user_id == to_string(socket.assigns.user_id) do
      push(socket, event, payload)
    end

    {:noreply, socket}
  end
end
