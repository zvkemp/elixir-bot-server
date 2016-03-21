defmodule Slack.Bot.Socket do
  @moduledoc """
  Simple server wrapper around a websocket
  """

  # TODO: Make this die on Websocket disconnects / errors
  use GenServer

  def start_link(name, ws_url, client) do
    GenServer.start_link(__MODULE__, {:ok, ws_url, client}, name: name)
  end

  # CALLBACKS

  def handle_call({ :push, payload }, _from, {socket, client}) do
    outcome = socket |> send_payload(payload, client)
    { :reply, outcome, {socket, client}}
  end

  def handle_call({ :recv }, _from, {socket, client}) do
    { :reply, socket |> recv(client), {socket, client}}
  end

  def handle_call({ :socket }, _from, state) do
    { :reply, state, state }
  end

  def init({ :ok, ws_url, client }) do
    { :ok, {connect(ws_url, client),client}}
  end

  # SOCKET MANAGEMENT

  defp connect(ws_url, client) do
    %{ host: host, path: path } = URI.parse(ws_url)
    client.connect!(host, path: path, secure: true)
  end

  defp send_payload(socket, payload, client) do
    socket |> client.send!({ :text, Poison.encode!(payload) })
  end

  def recv(socket, client) do
    response = socket |> client.recv
    case response do
      { :ok, { :text, body } } -> Poison.decode!(body)
      { :ok, { :ping, _    } } -> { :ping }
      e -> raise "Something went wrong: #{inspect e}"
    end
  end
end
