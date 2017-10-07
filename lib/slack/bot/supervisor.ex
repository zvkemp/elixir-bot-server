defmodule Slack.Bot.Supervisor do
  use Supervisor

  def start_link(%{name: name} = config) do
    Supervisor.start_link(__MODULE__, config, name: "#{name}:supervisor" |> String.to_atom)
  end

  # ---

  def init(%Slack.Bot.Config{} = c) do
    {uid, ws_url, channels} = init_api_calls(c.api_client, c.token, c.name)
    Agent.start_link(fn -> channels end, name: :"#{c.name}:channels")

    children = [
      worker(Slack.Bot,                    [:"#{c.name}:bot", Map.put(c, :id, uid)]),
      worker(Slack.Bot.Socket,             [:"#{c.name}:socket", ws_url, c.socket_client, :"#{c.name}:bot"]),
      worker(Slack.Bot.MessageTracker,     [:"#{c.name}:message_tracker", :"#{c.name}:bot", c.ping_frequency || 10_000]),
      worker(Slack.Bot.Outbox,             [:"#{c.name}:outbox", :"#{c.name}:socket", c.rate_limit])
    ]

    supervise(children, strategy: :rest_for_one)
  end

  defp init_api_calls(client, token, name) do
    %{
      "self" => %{"id" => uid},
      "url"  => ws_url
    } = response = client.auth_request(token, name)

    channels = response["channels"] |> Enum.filter(&(&1["is_member"]))
    private_channels = token |> client.list_groups |> Map.get("groups", [])

    channels_by_name = Enum.reduce(
      channels ++ private_channels,
      %{},
      fn (%{"name" => name} = c, acc) -> Map.put(acc, name, c) end
    )

    {uid, ws_url, channels_by_name}
  end
end
