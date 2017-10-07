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
  defp handle_payload(%{"type" => "ping", "id" => id} = msg, socket) do
    Queue.push(socket, %{"reply_to" => id, "type" => "pong"} |> Poison.encode!)
    Slack.Console.PubSub.broadcast("__pings__", msg, socket)
  end

  # outgoing
  defp handle_payload(%{"type" => "message"} = msg, socket) do
    Slack.Console.PubSub.broadcast(msg, socket)
  end
end