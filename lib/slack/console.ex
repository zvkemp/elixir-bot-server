defmodule Slack.Console do
  @moduledoc """
  Simulate a slack instance locally
  """
  use Supervisor

  def init(_args) do
    Supervisor.init([
      {Slack.Console.PubSub, []},
      supervisor(Registry, [:unique, :user_socket_registry])
    ], strategy: :one_for_one)
  end

  def start_link do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end
end

defmodule Slack.Console.PubSub do
  use GenServer
  require Logger

  def child_spec(_args) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, []}, restart: :permanent, shutdown: 5000, type: :worker}
  end

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:ok, %{}}
  end

  def subscribe(channel, socket, user_key) do
    GenServer.call(__MODULE__, {:subscribe, channel, socket, user_key})
  end

  def message(message) do
    broadcast("console", %{"text" => message, "channel" => "console", "type" => "message"}, nil)
  end

  def broadcast(message, socket) when is_pid(socket) do
    broadcast("console", message, socket)
  end

  def broadcast(channel, message, socket \\ nil) do
    GenServer.cast(__MODULE__, {:broadcast, channel, message, socket})
  end

  def handle_call({:subscribe, channel, socket, user_key}, from, channels) do
    new_state = Map.update(channels, channel, %{socket => user_key}, fn (ch) ->
      Map.put(ch, socket, user_key)
    end)
    {:reply, :ok, new_state}
  end

  def handle_cast({:broadcast, channel, unencoded_message, from_socket}, channels) do
    uid = channels[channel][from_socket] || "console user"
    message = Map.put(unencoded_message, "user", uid) |> Poison.encode!

    [:red, "[#{channel}]", :yellow, "[#{uid}] ", :green, unencoded_message["text"]]
    |> IO.ANSI.format
    |> IO.chardata_to_string
    |> IO.puts

    # Logger.debug("[#{channel}] :: #{message} #{inspect(uid)}")

    # don't deliver to sending socket
    queues = Map.get(channels, channel, %{})
             |> Map.keys
             |> Enum.filter(fn ^from_socket -> false; _ -> true end)
    Task.start(fn -> Enum.each(queues, fn q -> Queue.push(q, message) end) end)
    {:noreply, channels}
  end
end

defmodule Slack.Console.Socket do
  @moduledoc """
  Stands in for slack websocket client. `socket` refers to an inbound Queue genserver
  """
  require Logger

  # returns a pid
  def connect!(_host, opts) do
    Logger.info("connect: #{[_host, opts] |> inspect}")
    # path stands in for UID here
    do_connect!(opts[:path])
  end

  defp do_connect!(unique_key) do
    {:ok, q} = Queue.start_link
    Slack.Console.PubSub.subscribe("console", q, unique_key)
    q
  end

  def recv(socket) do
    # ping freq is 10_000
    case Queue.pop(socket, 11_000) do
      {:error, _} = e ->
        Logger.error({socket, e} |> inspect)
      val ->
        # Logger.info("<<< #{val} #{socket |> inspect}")
        {:ok, {:text, val }}
    end
  end

  def send!(socket, {:text, val} = payload) do
    # Logger.warn(">>> #{%{ sender: self(), socket: socket } |> inspect} sending #{val}")
    handle_payload(payload, socket)
  end

  defp handle_payload({:text, payload}, socket) do
    handle_payload(Poison.decode!(payload), socket)
  end

  # outgoing, but simulate pong response immediately
  defp handle_payload(%{"type" => "ping", "id" => id}, socket) do
    Queue.push(socket, %{"reply_to" => id, "type" => "pong"} |> Poison.encode!)
  end

  # outgoing
  defp handle_payload(%{"type" => "message"} = msg, socket) do
    Slack.Console.PubSub.broadcast(msg, socket)
  end
end

defmodule Slack.Console.APIClient do
  def auth_request(token) do
    %{ "self" => %{ "id" => token }, "url" => "internal/user/#{token}" }
  end
end
