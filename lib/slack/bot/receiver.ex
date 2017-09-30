defmodule Slack.Bot.Receiver do
  @moduledoc """
  Run in a Task as part of a Slack.Bot.Supervisor tree.
  Continually listens for incoming messages on the websocket.
  """

  # Recursively streams packets from the websocket to the Bot controller
  def start_link(bot, sock, client) do
    Task.start_link(new_recv_task(bot, sock, client))
  end

  defp new_recv_task(bot_server, socket, client_module) do
    fn -> new_recv(bot_server, socket, client_module) end
  end

  defp new_recv(bot_server, socket, client_module) do
    case client_module.recv(socket) do
      {:ok, {:text, body}} -> Poison.decode!(body)
      {:ok, {:ping, _}} -> {:ping}
      :ok -> nil
      e -> raise "Something went wrong: #{inspect e}"
    end |> Slack.Bot.EventHandler.handle(bot_server)

    new_recv(bot_server, socket, client_module)
  end
end
