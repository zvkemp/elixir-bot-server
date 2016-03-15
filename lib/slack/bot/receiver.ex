defmodule Slack.Bot.Receiver do
  @moduledoc """
  Run in a Task as part of a Slack.Bot.Supervisor tree.
  Continually listens for incoming messages on the websocket.
  """

  # Recursively streams packets from the websocket to the Bot controller
  def recv_task(bot_server, socket_server) do
    fn -> recv(bot_server, socket_server) end
  end

  # this is called until the socket is available
  defp recv(bot_server, socket_server) do
    sock = wait_for_socket(socket_server)
    recv(bot_server, socket_server, sock)
  end

  # this is called recursively until the supervisor exits.
  defp recv(bot_server, socket_server, socket) do
    # EventHandler spawning should possibly be moved to Bot, as there is more immediately
    # available metadata about how to respond and parse the message
    Slack.Websocket.recv(socket) |> Slack.Bot.EventHandler.handle(bot_server)
    recv(bot_server, socket_server, socket)
  end

  defp wait_for_socket(server) do
    IO.puts("wait_for_socket")
    cond do
      Process.whereis(server) -> GenServer.call(server, { :socket })
      true ->
        :timer.sleep(500)
        wait_for_socket(server)
    end
  end
end
