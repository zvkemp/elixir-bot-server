defmodule Slack.Bot.ReceiverTest do
  use ExUnit.Case

  alias Slack.{TestHelpers, TestMessageForwarder}

  setup do
    bot = TestHelpers.new_bot_name
    {:ok, queue} = Queue.start_link
    {:ok, server} = Slack.Bot.Receiver.start_link(bot, queue, Slack.Console.Socket)
    TestMessageForwarder.start_as(bot, Slack.Bot)
    {:ok, %{queue: queue, server: server, bot: bot}}
  end

  test "received messages are decoded and forwarded to the bot as an event", %{
    queue: queue,
    server: server,
    bot: bot
  } do
    Queue.push(queue, "{\"hello\": \"world\"}")
    assert_receive({Slack.Bot, {:event, %{"hello" => "world"}}})
  end
end
