defmodule Slack.BotTest.Integration do
  use ExUnit.Case, async: true
  setup_all do
    [name, token] = [6, 9] |> Enum.map(&(:crypto.rand_bytes(&1) |> Base.encode64))
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
    Process.register(self, :"RECV:#{token}")
    { :ok, context }
  end

  # async test example
  test "ping", %{ name: name, token: token } do
    Slack.Bot.ping!(name)
    assert_receive({:test_payload, ^token, data})
    assert %{ "type" => "ping" } = data
  end

  test "automatic pings", %{ name: name, token: token } do
    assert_receive({ :test_payload, ^token, data }, 200)
    assert %{ "type" => "ping" } = data
  end

  test "say with default channel", %{ name: name, token: token } do
    Slack.Bot.ping!(name)
    Slack.Bot.say(name, "hey there", "CHANNEL")
    assert_receive({:test_payload, ^token, data})
    assert_receive({:test_payload, ^token, data2})
    assert %{
      "type"    => "message",
      "text"    => "hey there",
      "channel" => "CHANNEL"
    } = data2
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
