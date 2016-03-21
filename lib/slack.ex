defmodule Slack do
  use Application

  def start(_type, _args) do
    Slack.BotRegistry.start_link(bot_configs)
  end

  def start_bot(name) when is_binary(name) or is_atom(name) do
    config = bot_configs |> Enum.find(fn (%{ name: n }) -> n == name end)
    start_bot(config)
  end

  def start_bot(%{} = config) do
    Slack.Bot.Supervisor.start_link(config)
  end

  def default_channel do
    Application.get_env(:slack, :default_channel)
  end

  def stop_bot(name) do
    Supervisor.stop(:"#{name}:supervisor")
  end

  defp default_bot_config do
    bot_configs |> Enum.at(0)
  end

  defp bot_configs do
    Application.get_env(:slack, :bots, [])
  end
end
