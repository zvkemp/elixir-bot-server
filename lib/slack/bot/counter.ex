defmodule Slack.Bot.Counter do
  @moduledoc """
  Tracks and increments a message counter to provide unique :id attributes
  on sent messages
  """

  use GenServer

  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, name: name)
  end

  def tick(pid) do
    GenServer.call(pid, { :tick })
  end

  def current(pid) do
    GenServer.call(pid, { :current })
  end

  def init(:ok) do
    { :ok, 1 }
  end

  def handle_call({ :current }, _from, n) do
    { :reply, n, n }
  end

  def handle_call({ :tick }, _from, n) do
    n = n + 1
    { :reply, n, n }
  end
end
