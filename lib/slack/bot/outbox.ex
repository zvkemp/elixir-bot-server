defmodule Slack.Bot.Outbox do
  use GenServer
  import Slack.BotRegistry

  def start_link(name, rate_limit \\ 1000) do
    GenServer.start_link(__MODULE__, {:ok, name, rate_limit}, name: registry_key(name, __MODULE__))
  end

  @impl true
  def handle_cast({:push, msg}, {name, rate_limit}) do
    require Logger
    sleeper = Task.async(fn -> :timer.sleep(rate_limit) end)
    GenServer.call(registry_key(name, Slack.Bot.Socket), {:push, msg})
    Task.await(sleeper)
    {:noreply, {name, rate_limit}}
  end

  @impl true
  def init({:ok, name, rate_limit}) do
    {:ok, {name, rate_limit}}
  end
end
