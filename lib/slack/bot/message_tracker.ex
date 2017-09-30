defmodule Slack.Bot.MessageTracker do
  @moduledoc """
  Keeps a receipt of sent messages until an incoming message
  arrives with the same "reply_to" id.
  """

  use GenServer
  require Logger

  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, name: name)
  end

  def init(:ok) do
    {:ok, {%{}, 1}}
  end

  def handle_call({:push, %{id: id} = payload}, _from, {state, counter}) do
    Logger.warn("push #{{id, payload} |> inspect}")
    {:reply, {:ok, id}, {Map.put(state, id, payload), counter}}
  end
  def handle_call({:push, payload}, _from, {state, counter}) do
    counter = counter + 1
    {:reply, {:ok, counter}, {Map.put(state, counter, payload), counter}}
  end

  def handle_call({:reply, id, payload}, _from, {state, counter}) do
    Logger.warn("reply #{{id, payload} |> inspect}")
    {:reply, :ok, {Map.delete(state, id), counter}}
  end

  def handle_call(:outstanding?, _from, {state, counter}) do
    { :reply, Enum.any?(state), {state, counter}}
  end

  def handle_call(:current, _from, state) do
    { :reply, state, state }
  end
end
