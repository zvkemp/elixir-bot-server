defmodule Slack.Bot.Data do
  @moduledoc """
  Bot-specific datastore
  """

  use GenServer

  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, name: name)
  end

  def init(:ok) do
    { :ok, %{} }
  end

  def handle_call({ :current }, _from, state) do
    { :reply, state, state }
  end

  def handle_call({ :update, new_data }, _from, data) do
    { :reply, true, Map.merge(data, new_data) }
  end
end
