defmodule Slack.Bot do
  @moduledoc """
  Provides a public interface (:ping!, :say, etc)
  and coordinates the interaction between the other servers on
  the supervision tree.
  """
  use GenServer
  require Logger

  import Slack.BotRegistry

  defmodule Config do
    defstruct [
      id: nil, # Usually set by the result of an API call
      name: nil,
      socket_client: Socket.Web,
      api_client: Slack.API,
      token: nil,
      ribbit_msg: nil,
      responder: nil,
      keywords: %{},
      ping_frequency: 10_000,
      rate_limit: 1 # messages per second
    ]
  end

  alias Slack.Bot.Config

  @spec start_link(atom, %Config{}) :: GenServer.on_start()
  def start_link(name, config) do
    GenServer.start_link(__MODULE__, config, name: name)
  end

  @spec ping!(atom) :: :ok
  def ping!(name), do: send_payload(name, %{type: "ping"})

  @spec say(atom, String.t | nil, String.t | nil) :: :ok
  def say(name, text, _channel \\ nil)

  def say(_, nil, _), do: :ok

  def say(name, text, channel) do
    send_payload(name, %{type: "message", text: text, channel: channel || default_channel()})
  end

  # for api
  def say_to_named_channel(name, text, channel_name) do
    case get_channel_id(name, channel_name) do
      :error -> :error
      id -> say(name, text, id)
    end
  end

  defp get_channel_id(name, channel_name) do
    Agent.get(:"#{name}:channels", fn map ->
      map
      |> Map.get(channel_name, %{})
      |> Map.get("id", :error)
    end)
  end

  # ---

  @impl true
  @spec init({atom, %Config{}, map()}) :: {:ok, %Config{}}
  def init(%Config{} = config) do
    {:ok, config}
  end

  @impl true
  @spec init(%{}) :: {:ok, %Config{}}
  def init(%{} = config) do
    {:ok, Map.merge(%Config{}, config)}
  end

  @spec default_channel() :: binary()
  defp default_channel do
    Slack.default_channel
  end

  @spec handle_cast(:ping | {:event, map()} | {:mod_config, map()}, %Config{}) :: {:noreply, %Config{}}
  @impl true
  def handle_cast(:ping, config) do
    ping!(config.name)
    {:noreply, config}
  end

  @impl true
  def handle_cast({:event, payload}, config) do
    process_receipt(config.name, payload, config)
    {:noreply, config}
  end

  @impl true
  def handle_cast({:mod_config, data}, state) do
    {:noreply, Map.merge(state, data)}
  end

  # append new message id to payloads with none
  @spec send_payload(atom, map()) :: :ok
  defp send_payload(name, payload) do
    {:ok, id} = GenServer.call(registry_key(name, :message_tracker), {:push, payload})
    GenServer.cast(registry_key(name, :outbox), {:push, Map.put(payload, :id, id)})
  end

  # NOTE: removed the "ok" => true matcher (not included in pongs).
  # May want to re-add it at some point.
  defp process_receipt(name, %{"reply_to" => id} = msg, _config) do
    # IO.inspect({:receipt, msg})
    GenServer.call(registry_key(name, :message_tracker), {:reply, id, msg})
  end

  defp process_receipt(name, %{"type" => "message"} = msg, config) do
    apply(config.responder, :respond, [name, msg, config])
  end

  defp process_receipt(name, %{"type" => "hello"}, _config) do
    Logger.info("[bot:#{name}] Received \"hello\".")
  end

  defp process_receipt(name, msg, _config) do
    Logger.debug(fn -> "[bot:#{name}] Received unhandled: #{inspect(msg)}" end)
  end
end
