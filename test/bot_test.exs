defmodule Slack.BotTest.Integration do
  use ExUnit.Case, async: true
  import Slack.BotRegistry

  alias Slack.Bot.{MessageTracker}

  @doc """
  proxies a subscription; forwards decoded JSON back to exunit for better
  pattern matching on messages
  """
  def subscribe_to_json(workspace, channel) do
    me = self()
    user_key = Base.encode64(:crypto.strong_rand_bytes(5))
    pid = spawn_link(fn -> json_recv(me) end)
    Slack.Console.PubSub.subscribe(workspace, channel, pid, user_key)
  end

  defp json_recv(forward_to_pid) do
    receive do
      {:push, json} -> send(forward_to_pid, {:json, Poison.decode!(json)})
    end
    json_recv(forward_to_pid)
  end

  setup_all do
    [name, token] = [6, 9] |> Enum.map(&(:crypto.strong_rand_bytes(&1) |> Base.encode64))

    # NOTE: There are also 6 bots on two workspaces configured by default; see config/test.exs
    config = %Slack.Bot.Config{
      name: name,
      token: token,
      api_client: Slack.Console.APIClient,
      workspace: "exunit",
      socket_client: Slack.Console.Socket,
      ping_frequency: 100,
      rate_limit: 0
    }

    Slack.Supervisor.start_bot(config)
    {:ok, %{config: config |> Map.merge(%{ name: {"exunit", name}})}}
  end

  setup %{config: %{token: _token}} = context do
    subscribe_to_json("exunit", "console")
    subscribe_to_json("exunit", "__pings__")
    {:ok, context}
  end

  test "automatic pings", %{config: %{name: _name, token: _token}} do
    assert_receive({:json, %{"type" => "ping"}}, 120)
  end

  test "manual pings", %{config: %{name: name}} do
    Slack.Bot.ping!(name)
    assert_receive({:json, data}, 25) # first automatic ping would not have been received yet
    assert_receive({:json, _}, 120) # automatic ping
  end

  test "say with default channel", %{config: %{ name: name, token: _token }} do
    channel = "console"
    message = "hey there"
    Slack.Bot.say(name, message, channel)

    assert_receive({:json, %{
      "type"    => "message",
      "text"    => ^message,
      "channel" => ^channel,
      "id"      => msg_id
    }})
    # tracks the message
    state = GenServer.call(registry_key(name, MessageTracker), :current)
    assert message == state.messages[msg_id][:text]
    :timer.sleep(15) # TODO: replace this wait with something more deterministic
    # cleans up the message upon server receipt
    assert %{messages: %{}} = GenServer.call(registry_key(name, MessageTracker), :current)
  end

  test "multitenancy: responses are segregated by workspace", _config do
    subscribe_to_json("workspace-a", "console")
    Slack.Console.say({"workspace-a", "console", "Hey there frogbot"})

    assert_receive({:json, %{"text" => "Hey there frogbot", "user" => "console user"}})
    assert_receive({:json, %{"text" => "ribbit-workspace-a", "user" => "/user/frogbot"}})
    refute_receive({:json, %{"text" => "ribbit-workspace-b", "user" => "/user/frogbot"}})

    subscribe_to_json("workspace-b", "console")
    Slack.Console.say({"workspace-b", "console", "Hey there toadbot"})
    refute_receive({:json, %{"text" => "croak-workspace-a", "user" => "/user/toadbot"}})
    assert_receive({:json, %{"text" => "croak-workspace-b", "user" => "/user/toadbot"}})
  end
end
