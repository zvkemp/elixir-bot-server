defmodule Slack.Bot.Socket do
  @moduledoc """
  Simple server wrapper around a websocket
  """

  alias Slack.Bot.{Receiver}
  import Slack.BotRegistry

  # TODO: Make this die on Websocket disconnects / errors (or handle "type" => "reconnect_url" messages)
  use GenServer

  def start_link(name, ws_url, client) do
    GenServer.start_link(__MODULE__, {:ok, ws_url, client, name}, name: registry_key(name, __MODULE__))
  end

  # CALLBACKS
  @impl true
  def init({:ok, ws_url, client, bot_name}) do
    {:ok, {connect(ws_url, client, bot_name), client}}
  end

  @impl true
  def handle_call({:push, payload}, _from, {socket, client}) do
    outcome = socket |> send_payload(payload, client)
    {:reply, outcome, {socket, client}}
  end

  def handle_call(:socket_pid, _from, {socket, _} = s) do
    {:reply, socket, s}
  end

  # SOCKET MANAGEMENT

  defp connect(ws_url, client, bot_name) do
    %{host: host, path: path} = URI.parse(ws_url)
    sock = client.connect!(host, path: path, secure: true)
    {:ok, _pid} = Receiver.start_link(bot_name, sock, client)
    sock
  end

  defp send_payload(socket, payload, client) do
    socket |> client.send!({:text, Poison.encode!(payload)})
  end
end
