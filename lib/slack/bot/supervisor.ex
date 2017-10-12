defmodule Slack.Bot.Supervisor do
  use Supervisor
  import Slack.BotRegistry
  alias Slack.Bot

  def start_link(%{name: name, workspace: ws} = config) do
    Supervisor.start_link(__MODULE__, config, name: registry_key({ws, name}, __MODULE__))
  end

  # ---

  def init(%Slack.Bot.Config{} = c) do
    name = {c.workspace, c.name}
    {uid, ws_url, channels} = init_api_calls(c.api_client, c.token, name)
    Agent.start_link(fn -> channels end, name: registry_key(name, :channels))

    children = [
      worker(Bot,                [name, Map.merge(c, %{id: uid, name: name})]),
      worker(Bot.Socket,         [name, ws_url, c.socket_client]),
      worker(Bot.MessageTracker, [name, c.ping_frequency || 10_000]),
      worker(Bot.Outbox,         [name, c.rate_limit])
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
