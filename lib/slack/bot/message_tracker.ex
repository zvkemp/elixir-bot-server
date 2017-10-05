defmodule Slack.Bot.MessageTracker do
  @moduledoc """
  Keeps a receipt of sent messages until an incoming message
  arrives with the same "reply_to" id.
  """

  use GenServer

  defmodule State do
    defstruct messages: %{}, counter: 1, ping_ref: nil, bot: nil, ping_freq: 10_000
  end

  alias Slack.Bot.MessageTracker.State, as: S

  @ping_ms 10_000

  def start_link(name, bot, ping_freq \\ @ping_ms) do
    GenServer.start_link(__MODULE__, {bot, ping_freq}, name: name)
  end

  @impl true
  @spec init({atom, integer}) :: {:ok, %S{}}
  def init({bot, ping_freq}) do
    {:ok, %S{ping_ref: reset_ping_timer(ping_freq), bot: bot, ping_freq: ping_freq}}
  end

  @impl true
  def handle_info(:ping, %S{} = s) do
    GenServer.cast(s.bot, :ping)
    {:noreply, %S{s | ping_ref: reset_ping_timer(s.ping_freq, s.ping_ref)}}
  end

  @spec reset_ping_timer(integer(), :timer.tref() | nil) :: :timer.tref()
  defp reset_ping_timer(ms, ping_ref \\ nil) do
    if ping_ref, do: :timer.cancel(ping_ref)
    {:ok, new_ping_ref} = :timer.send_after(ms, :ping)
    new_ping_ref
  end

  @impl true
  def handle_call({:push, payload}, _from, %S{} = s) do
    counter = s.counter + 1
    new_ping_ref = if payload[:type] == "ping", do: s.ping_ref, else: reset_ping_timer(s.ping_freq, s.ping_ref)

    {
      :reply,
      {:ok, counter},
      %S{s | messages: Map.put(s.messages, counter, payload), counter: counter , ping_ref: new_ping_ref}
    }
  end

  @impl true
  def handle_call({:reply, id, payload}, _from, %S{} = s) do
    {:reply, :ok, %S{s | messages: Map.delete(s.messages, id)}}
  end

  @impl true
  def handle_call(:current, _from, state) do
    {:reply, state, state}
  end
end
