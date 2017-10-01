defmodule Slack.Bot.Supervisor do
  use Supervisor

  def start_link(%{ name: name } = config) do
    Supervisor.start_link(__MODULE__, { :ok, config }, name: "#{name}:supervisor" |> String.to_atom)
  end

  # ---

  def init({ :ok, %{ name: name, token: token } = config }) do
    api_client    = Map.get(config, :api_client, Slack.API)
    socket_client = Map.get(config, :socket_client, Socket.Web)
    %{
      "self" => %{ "id" => uid },
      "url"  => ws_url
    } = meta = api_client.auth_request(token, name)

    children = [
      worker(Slack.Bot,                    [:"#{name}:bot", Map.put(config, :id, uid)]),
      worker(Slack.Bot.Socket,             [:"#{name}:socket", ws_url, socket_client, :"#{name}:bot"]),
      worker(Slack.Bot.MessageTracker,     [:"#{name}:message_tracker", :"#{name}:bot", config[:ping_frequency] || 10_000]),
      worker(Slack.Bot.Outbox,             [:"#{name}:outbox", :"#{name}:socket", config[:rate_limit]]),
      # worker(Task,                         [Slack.Bot.Timer.ping_fn(:"#{name}:bot", config[:ping_frequency] || 10000)], id: :ping_timer)
    ]

    supervise(children, strategy: :rest_for_one)
  end
end
