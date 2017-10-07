defmodule Slack.BotTest.Integration do
  use ExUnit.Case, async: true
  import Slack.BotRegistry

  alias Slack.Bot.{MessageTracker}

  setup_all do
    [name, token] = [6, 9] |> Enum.map(&(:crypto.strong_rand_bytes(&1) |> Base.encode64))
    config = %Slack.Bot.Config{
      name: name,
      token: token,
      api_client: Slack.Console.APIClient,
      socket_client: Slack.Console.Socket,
      ping_frequency: 100,
      rate_limit: 0
    }

    Slack.Supervisor.start_bot(config)
    {:ok, %{config: config}}
  end

  setup %{config: %{token: _token}} = context do
    # SocketTestClient.register_test_receiver(self(), token)
    Slack.Console.PubSub.subscribe("console", self(), "exunit")
    Slack.Console.PubSub.subscribe("__pings__", self(), "exunit")
    {:ok, context}
  end

  test "automatic pings", %{config: %{name: _name, token: _token}} do
    assert_receive({:push, data}, 120)
    assert %{"type" => "ping"} = Poison.decode!(data)
  end

  test "manual pings", %{config: %{name: name}} do
    Slack.Bot.ping!(name)
    assert_receive({:push, data}, 25) # first automatic ping would not have been received yet
    assert_receive({:push, _}, 120) # automatic ping
  end

  test "say with default channel", %{config: %{ name: name, token: _token }} do
    channel = "console"
    message = "hey there"
    Slack.Bot.say(name, message, channel)

    assert_receive({:push, json_content})
    assert %{
      "type"    => "message",
      "text"    => ^message,
      "channel" => ^channel,
      "id"      => msg_id
    } = Poison.decode!(json_content)
    # tracks the message
    state = GenServer.call(registry_key(name, MessageTracker), :current)
    assert message == state.messages[msg_id][:text]
    :timer.sleep(15) # TODO: replace this wait with something more deterministic
    # cleans up the message upon server receipt
    assert %{messages: %{}} = GenServer.call(registry_key(name, MessageTracker), :current)
  end
end
