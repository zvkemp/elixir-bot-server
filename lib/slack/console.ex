defmodule Slack.Console do
  @moduledoc """
  Simulate a slack instance locally
  """
  use Supervisor

  def init(_args) do
    Supervisor.init([
      {Slack.Console.PubSub, []}
    ], strategy: :one_for_one)
  end

  def start_link do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def say(msg) do
    Slack.Console.PubSub.message(msg)
  end
end

defmodule Slack.Console.PubSub do
  @moduledoc """
  Acts as the remote side of the slack simulator
  """
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

  def handle_call({:subscribe, channel, socket, user_key}, _from, channels) do
    new_state = Map.update(channels, channel, %{socket => user_key}, fn (ch) ->
      Map.put(ch, socket, user_key)
    end)
    {:reply, :ok, new_state}
  end

  def handle_cast({:broadcast, channel, unencoded_message, from_socket}, channels) do
    uid     = channels[channel][from_socket] || "console user"
    message = unencoded_message |> Map.put("user", uid) |> Poison.encode!

    [:red, "[#{channel}]", :yellow, "[#{uid}] ", :green, unencoded_message["text"]]
    |> IO.ANSI.format
    |> IO.chardata_to_string
    |> IO.puts

    # Logger.debug("[#{channel}] :: #{message} #{inspect(uid)}")

    # don't deliver to sending socket
    queues = channels |> Map.get(channel, %{})
                      |> Map.keys
                      |> Enum.filter(fn
                        ^from_socket -> false
                        _ -> true
                      end) |> IO.inspect
    Task.start(fn -> Enum.each(queues, fn q -> Queue.push(q, message) end) end)
    send_receipt(unencoded_message, from_socket)
    {:noreply, channels}
  end

  defp send_receipt(_msg, nil), do: nil # was not sent by a bot

  defp send_receipt(msg, from_socket) do
    receipt = Map.merge(msg, %{
      "ts" => :os.system_time / 1_000_000_000,
      "ok" => true,
      "reply_to" => msg["id"]
    })

    Queue.push(from_socket, Poison.encode!(receipt))
  end
end

defmodule Slack.Console.Socket do
  @moduledoc """
  Stands in for slack websocket client module. `socket` refers to an inbound Queue genserver
  """
  require Logger

  # returns a pid
  def connect!(host, opts) do
    Logger.info("connect: #{[host, opts] |> inspect}")
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
        {:ok, {:text, val}}
    end
  end

  def send!(socket, {:text, _val} = payload) do
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
  use Slack.Behaviours.API

  @impl true
  def auth_request(token, internal_name) do
    %{"self" => %{"id" => token}, "url" => "user/#{internal_name}"}
  end

  @impl true
  def join_channel(_, _), do: %{}
end
