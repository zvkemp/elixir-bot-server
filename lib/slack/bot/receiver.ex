defmodule Slack.Bot.Receiver do
  @moduledoc """
  Run in a Task as part of a Slack.Bot.Supervisor tree.
  Continually listens for incoming messages on the websocket.
  """

  require Logger

  @doc """
  Recursively streams packets from the websocket to the Bot controller
  """
  @spec start_link(Slack.Bot.bot_name, pid, module) :: {:ok, pid}
  def start_link(bot, sock, client) do
    Task.start_link(recv_task(bot, sock, client))
  end

  defp recv_task(bot_server, socket, client_module) do
    fn -> recv(bot_server, socket, client_module) end
  end

  @spec recv(Slack.Bot.bot_name, pid, module) :: any
  defp recv(bot_server, socket, client_module) do
    event = case client_module.recv(socket) do
      {:ok, {:text, body}} -> Poison.decode!(body)
      {:ok, {:ping, _}} -> {:ping}
      :ok -> nil
      e -> raise "Something went wrong: #{inspect e}"
    end

    _ = Slack.Bot.EventHandler.handle(event, bot_server)
    recv(bot_server, socket, client_module)
  end
end
