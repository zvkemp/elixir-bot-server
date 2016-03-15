# Simple rate-limiting outbox - very much a WIP
defmodule Slack.Bot.Outbox do

  def start_link(name, socket_name) do
    GenServer.start_link(__MODULE__, { :ok, socket_name }, name: name)
  end

  def handle_cast({ :push, msg }, socket_name) do
    GenServer.call(socket_name, { :push, msg })
    :timer.sleep(1000) # hmmm
    { :noreply, socket_name }
  end

  def init({ :ok, socket_name }) do
    { :ok, socket_name }
  end
end
