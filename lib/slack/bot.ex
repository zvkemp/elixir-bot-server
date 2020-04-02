defmodule Slack.Bot do
  @moduledoc """
  Provides a public interface (:ping!, :say, etc)
  and coordinates the interaction between the other servers on
  the supervision tree.
  """
  use GenServer
  require Logger

  import Slack.BotRegistry
  import Slack, only: [default_channel: 0]
  alias Slack.Bot.{Outbox, MessageTracker}

  @typedoc """
  Tuple of {workspace, name}
  """
  @type bot_name :: {String.t(), String.t()}

  defmodule Config do
    @moduledoc false
    @enforce_keys [:workspace]
    # Usually set by the result of an API call
    # messages per second
    defstruct id: nil,
              name: nil,
              socket_client: Socket.Web,
              api_client: Slack.API,
              workspace: nil,
              token: nil,
              ribbit_msg: nil,
              responder: nil,
              keywords: %{},
              ping_frequency: 10_000,
              rate_limit: 1

    @type t :: %Config{}
  end

  alias Slack.Bot.Config

  @spec start_link(bot_name, Config.t()) :: GenServer.on_start()
  def start_link(name, config) do
    GenServer.start_link(__MODULE__, config, name: registry_key(name, __MODULE__))
  end

  @doc """
  Manually trigger a ping.

  ## Examples

      iex> Slack.Bot.ping!({"my-workspace", "frogbot"})
      :ok

  """
  @spec ping!(bot_name) :: :ok
  def ping!(name), do: send_payload(name, %{type: "ping"})

  @doc """
  Enqueue a message from the given bot to the given channel.

  ## Examples

     Slack.Bot.say("frogbot", nil) #=> :ok # (nothing happens)
     Slack.Bot.say("frogbot", "Hello, world") #=> :ok (message sent to default channel)
     Slack.Bot.say("frogbot", "Hello, world", "ABCDEF123") #=> :ok (message sent to channel given by channel id)

  """
  @spec say(bot_name, String.t() | nil, String.t() | nil) :: :ok
  def say(name, text, _channel \\ nil)

  def say(_, nil, _), do: :ok

  def say(name, text, channel_id) do
    send_payload(name, %{type: "message", text: text, channel: channel_id || default_channel()})
  end

  @doc """
  Attempts to look up a channel id by name, then sends the given message to it.
  """
  # TODO: update for multi-tenancy
  def say_to_named_channel(name, text, channel_name) do
    case get_channel_id(name, channel_name) do
      :error -> :error
      id -> say(name, text, id)
    end
  end

  # TODO: update for multi-tenancy
  @spec get_channel_id(bot_name, String.t()) :: String.t() | :error
  defp get_channel_id(name, channel_name) do
    Agent.get(registry_key(name, :channels), fn map ->
      map
      |> Map.get(channel_name, %{})
      |> Map.get("id", :error)
    end)
  end

  # ---

  @impl true
  @spec init(%Config{}) :: {:ok, %Config{}}
  def init(%Config{} = config) do
    {:ok, config}
  end

  @impl true
  @spec init(%{}) :: {:ok, %Config{}}
  def init(%{} = config) do
    {:ok, struct(Config, config)}
  end

  @spec handle_cast(:ping | {:event, map()} | {:mod_config, map()}, %Config{}) :: {
          :noreply,
          %Config{}
        }
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
  @spec send_payload(bot_name, map()) :: :ok
  defp send_payload(name, payload) do
    {:ok, id} = GenServer.call(registry_key(name, MessageTracker), {:push, payload})
    GenServer.cast(registry_key(name, Outbox), {:push, Map.put(payload, :id, id)})
  end

  # NOTE: removed the "ok" => true matcher (not included in pongs).
  # May want to re-add it at some point.
  @spec process_receipt(bot_name, map, %Config{}) :: any()
  defp process_receipt(name, %{"reply_to" => id} = msg, _config) do
    GenServer.call(registry_key(name, MessageTracker), {:reply, id, msg})
  end

  defp process_receipt(name, %{"type" => "message"} = msg, config) do
    apply(config.responder, :respond, [name, msg, config])
  end

  defp process_receipt({ws, name}, %{"type" => "hello"}, _config) do
    Logger.info("[bot:#{ws}:#{name}] Received \"hello\".")
  end

  defp process_receipt({ws, name}, msg, _config) do
    Logger.debug(fn -> "[bot:#{ws}:#{name}] Received unhandled: #{inspect(msg)}" end)
  end
end
