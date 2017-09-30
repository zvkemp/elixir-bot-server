defmodule Slack.BotTest.Integration do
  use ExUnit.Case, async: true
  setup_all do
    [name, token] = [6, 9] |> Enum.map(&(:crypto.strong_rand_bytes(&1) |> Base.encode64))
    config = %{
      name: name,
      token: token,
      api_client: SlackTestClient,
      socket_client: SocketTestClient,
      ping_frequency: 100,
      rate_limit: 0
    }

    Slack.start_bot(config)
    { :ok, config }
  end

  setup %{ token: token } = context do
    SocketTestClient.register_test_receiver(self, token)
    { :ok, context }
  end

  test "automatic pings", %{ name: name, token: token } do
    assert_receive({ :test_payload, ^token, data }, 200)
    assert %{ "type" => "ping" } = data
  end

  test "say with default channel", %{ name: name, token: token } do
    channel = "CHANNEL"
    message = "hey there"
    Slack.Bot.say(name, message, channel)
    assert_receive({:test_payload, ^token, %{
      "type"    => "message",
      "text"    => message,
      "channel" => channel,
      "id"      => msg_id
    }})

    # tracks the message
    {state, counter} = GenServer.call(:"#{name}:message_tracker", :current)
    assert message == state[msg_id][:text]
    :timer.sleep(15) # TODO: replace this wait with something more deterministic
    # cleans up the message upon server receipt
    assert {%{}, _} = GenServer.call(:"#{name}:message_tracker", :current)
  end
end

defmodule Slack.BotTest.Unit do
  use ExUnit.Case, async: true

  test ":init with map", config do
    assert Slack.Bot.init({ :ok, config }) == { :ok, config }
  end

  test ":init with anything else" do
    assert Slack.Bot.init({ :ok, "hello" }) == { :error, "hello" }
  end
end
