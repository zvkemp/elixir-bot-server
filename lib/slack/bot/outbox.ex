defmodule Slack.Bot.Outbox do
  use GenServer

  def start_link(name, socket_name, nil) do
    start_link(name, socket_name)
  end

  def start_link(name, socket_name, rate_limit \\ 1000) do
    GenServer.start_link(__MODULE__, {:ok, socket_name, rate_limit}, name: name)
  end

  @impl true
  def handle_cast({:push, msg}, {socket_name, rate_limit}) do
    require Logger
    sleeper = Task.async(fn -> :timer.sleep(rate_limit) end)
    GenServer.call(socket_name, {:push, msg})
    Task.await(sleeper)
    {:noreply, {socket_name, rate_limit}}
  end

  @impl true
  def init({:ok, socket_name, rate_limit}) do
    {:ok, {socket_name, rate_limit}}
  end
end
