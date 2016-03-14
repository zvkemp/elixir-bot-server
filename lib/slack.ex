defmodule Slack do
  use Application

  def start(_type, _args) do
    Slack.BotRegistry.start_link(bot_configs)
  end

  defp default_bot_config do
    bot_configs |> Enum.at(0)
  end

  defp bot_configs do
    Application.get_env(:slack, :bots)
  end

  def start_bot(name) do
    config = bot_configs |> Enum.find(fn (%{ name: n }) -> n == name end)
    Slack.Bot.Supervisor.start_link(config)
  end

  def stop_bot(name) do
    Supervisor.stop(:"#{name}:supervisor")
  end
end
