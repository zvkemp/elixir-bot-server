defmodule Slack.Bot.MessageTracker do
  @moduledoc """
  Keeps a receipt of sent messages until an incoming message
  arrives with the same "reply_to" id.
  """

  use GenServer

  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, name: name)
  end

  def init(:ok) do
    { :ok, %{} }
  end

  def handle_call({ :push, %{ id: id } = payload }, _from, state) do
    { :reply, :ok, Map.put(state, id, payload) }
  end

  def handle_call({ :reply, id, payload }, _from, state) do
    { :reply, :ok, Map.delete(state, id) }
  end

  def handle_call({ :outstanding? }, _from, state) do
    { :reply, Enum.any?(state), state }
  end
end
