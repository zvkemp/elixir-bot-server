defmodule Slack.Bot.Socket do
  @moduledoc """
  Simple server wrapper around a Slack.Websocket
  """

  # TODO: Make this die on Websocket disconnects / errors
  use GenServer

  def start_link(name, token) do
    GenServer.start_link(__MODULE__, { :ok, token }, name: name)
  end

  # ---

  def handle_call({ :push, payload }, _from, socket) do
    outcome = socket |> Slack.Websocket.send_payload(payload)
    { :reply, outcome, socket }
  end

  def handle_call({ :recv }, _from, socket) do
    outcome = socket |> Slack.Websocket.recv
    { :reply, outcome, socket }
  end

  def handle_call({ :socket }, _from, socket) do
    { :reply, socket, socket }
  end

  def init({ :ok, token }) do
    { socket, auth } = Slack.Websocket.connect_with_meta!(token)

    cond do
      %{ "self" => %{ "id" => id, "name" => name }} = auth ->
        GenServer.cast(:"#{name}:bot", { :mod_config, %{ id: id }})
      true -> nil
    end

    { :ok, Slack.Websocket.connect!(token) }
  end
end
