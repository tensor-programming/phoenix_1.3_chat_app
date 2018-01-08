defmodule ChatWeb.ChatRoomChannel do
  use ChatWeb, :channel

  def join("chat_room:lobby", payload, socket) do
    if authorized?(payload) do
      send(self(), :after_join)
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (chat_room:lobby).
  def handle_in("shout", payload, socket) do
    spawn(fn -> save_msg(payload) end)
    broadcast socket, "shout", payload
    {:noreply, socket}
  end

  def handle_info(:after_join, socket) do
    Chat.Message.get_msgs() 
    |> Enum.each(fn msg -> push(socket, "shout",
      %{
        name: msg.name,
        message: msg.message,
      }) end)
    {:noreply, socket}
  end

  # Add authorization logic here as required.

  defp save_msg(msg) do
    Chat.Message.changeset(%Chat.Message{}, msg) |> Chat.Repo.insert  
  end

  defp authorized?(_payload) do
    true
  end
end
