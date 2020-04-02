defmodule Slack.Bot.OutboxTest do
  use ExUnit.Case
  alias Slack.{TestHelpers, TestMessageForwarder}

  setup do
    bot = TestHelpers.new_bot_name()
    role = Slack.Bot.Socket
    TestMessageForwarder.start_as(bot, role)
    rate_limit = 200
    {:ok, server} = Slack.Bot.Outbox.start_link(bot, rate_limit)
    {:ok, %{server: server, bot: bot, rate_limit: rate_limit, role: role}}
  end

  test "limits outgoing messages to one per {rate limit}", %{
    role: role,
    server: server,
    rate_limit: rate_limit
  } do
    GenServer.cast(server, {:push, "foo"})
    GenServer.cast(server, {:push, "bar"})

    assert_receive({^role, {:push, "foo"}})
    refute_receive({_, {:push, "bar"}}, rate_limit)
    assert_receive({^role, {:push, "bar"}}, rate_limit * 2)
  end
end
