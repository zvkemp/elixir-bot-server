defmodule Slack.Bot.MessageTrackerTest do
  use ExUnit.Case
  import Slack.BotRegistry
  alias Slack.{TestHelpers, TestMessageForwarder, Bot}

  setup do
    bot = TestHelpers.new_bot_name()
    ping_frequency = 100
    {:ok, server} = Bot.MessageTracker.start_link(bot, ping_frequency)
    TestMessageForwarder.start_as(bot, Bot)
    {:ok, %{bot_name: bot, server: server}}
  end

  describe "pings" do
    test "automatic pings" do
      assert_receive({Bot, :ping}, 110)
      assert_receive({Bot, :ping}, 110)
      assert_receive({Bot, :ping}, 110)
    end

    test "ping timer is reset when outgoing messages are sent", %{server: server} do
      assert_receive({Bot, :ping}, 110)
      :timer.sleep(30)
      GenServer.call(server, {:push, %{type: "message", message: "msg"}})
      refute_receive({Bot, :ping}, 90)
      assert_receive({Bot, :ping}, 110)
    end
  end

  describe "message tracking" do
    test "outgoing messages are counted", %{server: server} do
      assert_receive({Bot, :ping}, 110)
      {:ok, counter} = GenServer.call(server, {:push, %{type: "message", message: "msg"}})
      assert %{messages: messages} = GenServer.call(server, :current)
      assert %{^counter => %{message: "msg", type: "message"}} = messages
    end

    test "incoming replies are acknowledged", %{server: server} do
      assert_receive({Bot, :ping}, 110)
      {:ok, counter} = GenServer.call(server, {:push, %{type: "message", message: "msg"}})
      GenServer.call(server, {:reply, counter, %{"reply_to" => counter}})
      assert %{messages: %{}} = GenServer.call(server, :current)
    end
  end
end
