defmodule Slack.Bot do
  @moduledoc """
  Provides a public interface (:ping!, :say, etc)
  and coordinates the interaction between the other servers on
  the supervision tree.
  """
  use GenServer

  def start_link(name, config) do
    GenServer.start_link(__MODULE__, { :ok, config }, name: name)
  end

  def ping!(name), do: send_payload(name, %{ type: "ping" })

  def say(name, text, channel \\ nil) do
    send_payload(name, %{ type: "message", text: text, channel: channel || default_channel })
  end

  # ---

  def init({ :ok, config }) do
    { :ok, config }
  end

  # TODO
  defp default_channel do
    Slack.default_channel
  end

  def handle_cast({ :ping }, %{ name: name } = state) do
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
  defp send_payload(name, %{ id: _id } = payload) do
    GenServer.call(:"#{name}:message_tracker", { :push, payload })
    GenServer.call(:"#{name}:socket", { :push, payload })
  end
  defp send_payload(name, payload) do
    send_payload(name, Map.put(payload, :id, new_message_id(name)) )
  end

  defp new_message_id(name) do
    GenServer.call(:"#{name}:counter", { :tick })
  end

  defp process_receipt(name, %{ "reply_to" => id, "ok" => true } = msg, config) do
    GenServer.call(:"#{name}:message_tracker", { :reply, id, msg })
  end

  # TODO
  defp process_receipt(name, msg, config) do
    try_echo(name, msg, config)
    msg |> IO.inspect
  end

  defp try_echo(name, %{ "text" => t, "type" => "message", "user" => user, "channel" => c }, %{ id: uid, ribbit_msg: r }) do
    uid_flag = "<@#{uid}>"
    cond do
      String.starts_with?(t, "#{name} echo ") || String.starts_with?(t, "#{uid_flag} echo ") ->
        say(name, String.split(t, " echo ", parts: 2) |> Enum.at(1), c)
      String.contains?(t, name) || String.contains?(t, uid_flag) ->
        say(name, r, c)
      true -> nil
    end
  end

  defp try_echo(_, _, _), do: nil
end
