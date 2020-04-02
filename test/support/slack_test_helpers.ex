defmodule Slack.TestHelpers do
  def new_bot_name do
    fn -> :crypto.strong_rand_bytes(16) end
    |> Stream.repeatedly
    |> Enum.take(2)
    |> List.to_tuple
  end

  @doc """
  proxies a subscription; forwards decoded JSON back to exunit for better
  pattern matching on messages
  """
  def subscribe_to_json(workspace, channel) do
    me = self()
    user_key = Base.encode64(:crypto.strong_rand_bytes(5))
    {:ok, pid} = Slack.TestMessageForwarder.start_as(
      {workspace, user_key},
      :json,
      fn {:push, json} -> Jason.decode!(json) end
    )
    Slack.Console.PubSub.subscribe(workspace, channel, pid, user_key)
  end
end
