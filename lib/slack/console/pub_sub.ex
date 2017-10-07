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

  @impl true
  def init(:ok) do
    {:ok, %{}}
  end

  def subscribe(channel, socket, user_key) do
    GenServer.call(__MODULE__, {:subscribe, channel, socket, user_key})
  end

  def message({channel, message}) do
    broadcast(channel, %{"text" => message, "channel" => channel, "type" => "message"}, nil)
  end

  def message(message) do
    message({"console", message})
  end

  def broadcast(message, socket) when is_pid(socket) do
    broadcast("console", message, socket)
  end

  def broadcast(channel, message, socket \\ nil) do
    GenServer.cast(__MODULE__, {:broadcast, channel, message, socket})
  end

  @impl true
  def handle_call({:subscribe, channel, socket, user_key}, _from, channels) do
    new_state = Map.update(channels, channel, %{socket => user_key}, fn (ch) ->
      Map.put(ch, socket, user_key)
    end)
    {:reply, :ok, new_state}
  end

  @impl true
  @spec handle_cast({:broadcast, binary(), map(), pid()}, map()) :: {:noreply, map()}
  def handle_cast({:broadcast, channel, unencoded_message, from_socket}, channels) do
    uid     = channels[channel][from_socket] || "console user"
    message = unencoded_message |> Map.put("user", uid) |> Poison.encode!
    text    = unencoded_message["text"]

    Slack.Console.print(channel, uid, text)
    queues = channels |> Map.get(channel, %{})
                      |> Map.keys
                      |> Enum.filter(fn
                        ^from_socket -> false
                        _ -> true
                      end)
    Task.start(fn -> Enum.each(queues, fn q -> send(q, {:push, message}) end) end)
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
