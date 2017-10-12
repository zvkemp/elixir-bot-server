defmodule Slack.Bot.EventHandler do
  import Slack.BotRegistry

  @spec handle(map | {:ping} | nil, Slack.Bot.bot_name) :: {:ok, pid}
  def handle(nil, _), do: nil
  def handle(event, bot_server) do
    Task.start(__MODULE__, :go, [event, bot_server])
  end

  @spec go(map | {:ping} | nil, Slack.Bot.bot_name) :: :ok
  def go(event, bot_server) do
    GenServer.cast(registry_key(bot_server, Slack.Bot), {:event, event})
  end
end
