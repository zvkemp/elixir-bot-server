defmodule Slack.Console.PubSub do
  @moduledoc """
  Acts as the remote side of the slack simulator
  """
  use GenServer
  require Logger

  def child_spec(_args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      restart: :permanent,
      shutdown: 5000,
      type: :worker
    }
  end

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    {:ok, {%{}, %{}}}
  end

  def subscribe(workspace, channel, socket, user_key) do
    GenServer.call(__MODULE__, {:subscribe, workspace, channel, socket, user_key})
  end

  def message({workspace, channel, message}) do
    broadcast(
      workspace,
      channel,
      %{"text" => message, "channel" => channel, "type" => "message"},
      nil
    )
  end

  def message(message) do
    message({"console-workspace", "console", message})
  end

  # def broadcast(channel, message, socket) when is_pid(socket) do
  # broadcast(workspace, "console", message, socket)
  # end
  def broadcast(channel, message, socket) when is_pid(socket) do
    GenServer.cast(__MODULE__, {:broadcast, channel, message, socket})
  end

  def broadcast(workspace, channel, message, socket \\ :null_socket) do
    GenServer.cast(__MODULE__, {:broadcast, workspace, channel, message, socket})
  end

  @impl true
  def handle_call({:subscribe, workspace, channel, socket, user_key}, _from, {
        channels,
        workspaces
      }) do
    # TODO: raise error if changing workspaces (shouldn't happen)
    new_workspaces = Map.put(workspaces, socket, workspace)

    new_channels =
      Map.update(channels, {workspace, channel}, %{socket => user_key}, fn ch ->
        Map.put(ch, socket, user_key)
      end)

    {:reply, :ok, {new_channels, new_workspaces}}
  end

  @impl true
  def handle_cast({:broadcast, channel, message, from}, {_, workspaces} = state) do
    workspace = Map.fetch!(workspaces, from)
    handle_cast({:broadcast, workspace, channel, message, from}, state)
  end

  @impl true
  @spec handle_cast({:broadcast, String.t(), String.t(), map, pid}, {map, map}) :: {
          :noreply,
          {map, map}
        }
  def handle_cast(
        {:broadcast, workspace, channel, unencoded_message, from_socket},
        {channels, _} = state
      ) do
    ts = System.os_time(:microsecond) / 1_000_000
    channel_key = {workspace, channel}
    uid = channels[channel_key][from_socket] || "console user"

    message = unencoded_message |> Map.merge(%{"user" => uid, "ts" => "#{ts}"}) |> Jason.encode!()

    text = unencoded_message["text"]

    Slack.Console.print(workspace, channel, uid, text)

    queues =
      channels
      |> Map.get(channel_key, %{})
      |> Map.keys()
      |> Enum.filter(fn
        ^from_socket -> false
        _ -> true
      end)

    {:ok, _} = Task.start(fn -> Enum.each(queues, fn q -> send(q, {:push, message}) end) end)
    send_receipt(unencoded_message, from_socket)
    {:noreply, state}
  end

  # was not sent by a bot
  defp send_receipt(_msg, nil), do: nil

  defp send_receipt(msg, from_socket) do
    receipt =
      Map.merge(msg, %{
        "ts" => :os.system_time() / 1_000_000_000,
        "ok" => true,
        "reply_to" => msg["id"]
      })

    Queue.push(from_socket, Jason.encode!(receipt))
  end
end
