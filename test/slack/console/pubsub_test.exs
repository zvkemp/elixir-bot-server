defmodule Slack.Console.PubSubTest do
  use ExUnit.Case

  setup do
    {:ok, pid} = GenServer.start_link(Slack.Console.PubSub, :ok)
    {:ok, %{pid: pid}}
  end

  test "subscribing", _config do
    Slack.Console.PubSub.subscribe("workspace-1", "channel-1", self(), "user-1")
    Slack.Console.PubSub.message({"workspace-1", "channel-1", "foo"})
    assert_receive({:push, _}, 50)
  end

  test "alternate workspaces don't trigger push", _config do
    Slack.Console.PubSub.subscribe("workspace-1", "channel-1", self(), "user-1")
    Slack.Console.PubSub.message({"workspace-2", "channel-1", "foo"})
    refute_receive({:push, _}, 50)
  end
end
