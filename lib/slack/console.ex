defmodule Slack.Console do
  @moduledoc """
  Simulate a slack instance locally (intended for dev/test environments)
  Add the following config to a bot to override the default socket and api clients:

   socket_client: Slack.Console.Socket,
   api_client: Slack.Console.APIClient,

  (This setting is per-bot)
  """
  use Supervisor

  def init(_args) do
    Supervisor.init([
      {Slack.Console.PubSub, []}
    ], strategy: :one_for_one)
  end

  def start_link do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def say(msg) do
    Slack.Console.PubSub.message(msg)
  end

  def print(_channel, _uid, nil), do: :ok
  def print(channel, uid, text) do
    if Application.get_env(:slack, :print_to_console), do:
      [:red, "[#{channel}]", :yellow, "[#{uid}] ", :green, text]
      |> IO.ANSI.format
      |> IO.chardata_to_string
      |> IO.puts
  end
end
