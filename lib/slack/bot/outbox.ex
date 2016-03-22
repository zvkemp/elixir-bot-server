# Simple rate-limiting outbox - very much a WIP
defmodule Slack.Bot.Outbox do

  def start_link(name, socket_name, nil) do
    start_link(name, socket_name)
  end

  def start_link(name, socket_name, rate_limit \\ 1000) do
    GenServer.start_link(__MODULE__, { :ok, socket_name, rate_limit }, name: name)
  end

  def handle_cast({ :push, msg }, { socket_name, rate_limit }) do
    GenServer.call(socket_name, { :push, msg })
    :timer.sleep(rate_limit) # hmmm
    { :noreply, {socket_name, rate_limit} }
  end

  def init({ :ok, socket_name, rate_limit }) do
    { :ok, {socket_name, rate_limit}}
  end
end
