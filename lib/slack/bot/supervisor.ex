defmodule Slack.Bot.Supervisor do
  use Supervisor

  def start_link(%{name: name} = config) do
    Supervisor.start_link(__MODULE__, config, name: "#{name}:supervisor" |> String.to_atom)
  end

  # ---

  def init(%Slack.Bot.Config{} = c) do
    %{
      "self" => %{"id" => uid},
      "url"  => ws_url
    } = c.api_client.auth_request(c.token, c.name)

    children = [
      worker(Slack.Bot,                    [:"#{c.name}:bot", Map.put(c, :id, uid)]),
      worker(Slack.Bot.Socket,             [:"#{c.name}:socket", ws_url, c.socket_client, :"#{c.name}:bot"]),
      worker(Slack.Bot.MessageTracker,     [:"#{c.name}:message_tracker", :"#{c.name}:bot", c.ping_frequency || 10_000]),
      worker(Slack.Bot.Outbox,             [:"#{c.name}:outbox", :"#{c.name}:socket", c.rate_limit])
    ]

    supervise(children, strategy: :rest_for_one)
  end
end
