defmodule Slack.Bot do
  @moduledoc """
  Provides a public interface (:ping!, :say, etc)
  and coordinates the interaction between the other servers on
  the supervision tree.
  """
  use GenServer
  require Logger

  def start_link(name, config) do
    GenServer.start_link(__MODULE__, { :ok, config }, name: name)
  end

  def ping!(name), do: send_payload(name, %{type: "ping"})

  def say(name, text, channel \\ nil) do
    send_payload(name, %{ type: "message", text: text, channel: channel || default_channel() })
  end

  # ---

  def init({ :ok, %{} = config }) do
    { :ok, config }
  end

  def init({ :ok, _ = config }) do
    { :error, config }
  end

  # TODO
  defp default_channel do
    Slack.default_channel
  end

  def handle_cast(:ping, %{ name: name } = state) do
    ping!(name)
    { :noreply, state }
  end

  def handle_cast({ :event, payload }, %{ name: name } = state) do
    process_receipt(name, payload, state)
    { :noreply, state }
  end

  def handle_cast({ :mod_config, data }, state) do
    { :noreply, Map.merge(state, data) }
  end

  # append new message id to payloads with none
  defp send_payload(name, payload) do
    {:ok, id} = GenServer.call(:"#{name}:message_tracker", {:push, payload})
    GenServer.cast(:"#{name}:outbox", {:push, Map.put(payload, :id, id)})
  end

  # NOTE: removed the "ok" => true matcher (not included in pongs).
  # May want to re-add it at some point.
  defp process_receipt(name, %{ "reply_to" => id } = msg, _config) do
    GenServer.call(:"#{name}:message_tracker", { :reply, id, msg })
  end

  defp process_receipt(name, %{ "type" => "message" } = msg, %{ responder: responder } = c) do
    apply(responder, :respond, [name, msg, c])
  end

  defp process_receipt(name, %{ "type" => "hello" }, _config) do
    Logger.info("[bot:#{name}] Received \"hello\".")
  end

  defp process_receipt(_name, _msg, _config), do: nil
end
