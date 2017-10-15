defmodule Slack.Bot.MessageTracker do
  @moduledoc """
  Keeps a receipt of sent messages until an incoming message
  arrives with the same "reply_to" id.

  Sends a ping if no messages have been sent for 10 seconds (or the configured frequency value).
  """

  use GenServer
  alias Slack.Bot
  alias Slack.Bot.MessageTracker.State, as: S
  import Slack.BotRegistry

  defmodule State do
    defstruct messages: %{}, counter: 1, ping_ref: nil, name: nil, ping_freq: 10000
  end

  @ping_ms 10000

  @spec start_link(Slack.Bot.bot_name(), integer) :: GenServer.on_start()
  def start_link(name, ping_freq \\ @ping_ms) do
    GenServer.start_link(__MODULE__, {name, ping_freq}, name: registry_key(name, __MODULE__))
  end

  @impl true
  @spec init({Slack.Bot.bot_name(), integer}) :: {:ok, %S{}}
  def init({name, ping_freq}) do
    {:ok, %S{ping_ref: reset_ping_timer(ping_freq), name: name, ping_freq: ping_freq}}
  end

  @impl true
  def handle_info(:ping, %S{} = s) do
    GenServer.cast(registry_key(s.name, Bot), :ping)
    {:noreply, %S{s | ping_ref: reset_ping_timer(s.ping_freq, s.ping_ref)}}
  end

  @spec reset_ping_timer(integer(), :timer.tref() | nil) :: :timer.tref()
  defp reset_ping_timer(ms, ping_ref \\ nil) do
    if ping_ref, do: _ = :timer.cancel(ping_ref)
    {:ok, new_ping_ref} = :timer.send_after(ms, :ping)
    new_ping_ref
  end

  @impl true
  def handle_call({:push, payload}, _from, %S{} = s) do
    counter = s.counter + 1

    new_ping_ref =
      if payload[:type] == "ping", do: s.ping_ref, else: reset_ping_timer(s.ping_freq, s.ping_ref)

    {
      :reply,
      {:ok, counter},
      %S{
        s
        | messages: Map.put(s.messages, counter, payload),
          counter: counter,
          ping_ref: new_ping_ref
      }
    }
  end

  @impl true
  def handle_call({:reply, id, _payload}, _from, %S{} = s) do
    {:reply, :ok, %S{s | messages: Map.delete(s.messages, id)}}
  end

  @impl true
  def handle_call(:current, _from, state) do
    {:reply, state, state}
  end
end
