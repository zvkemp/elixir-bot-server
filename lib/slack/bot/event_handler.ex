defmodule Slack.Bot.EventHandler do
  import Slack.BotRegistry
  # NOTE: almost certainly unnecessary to wrap a cast in a task
  def handle(event, bot_server) do
    Task.start(__MODULE__, :go, [event, bot_server])
  end

  def go(event, bot_server) do
    GenServer.cast(registry_key(bot_server, Slack.Bot), {:event, event})
  end
end
