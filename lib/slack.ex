defmodule Slack do
  use Application

  def start(_type, _args) do
    Slack.Supervisor.start_link()
  end

  def default_channel do
    Application.get_env(:slack, :default_channel)
  end
end

defmodule Slack.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_arg) do
    registry_spec = supervisor(Registry, [[keys: :unique, name: Slack.BotRegistry]])

    bot_specs =
      bot_configs()
      |> Task.async_stream(&bot_config_to_spec/1)
      |> Enum.map(fn {:ok, {%{name: bot} = config, data}} ->
        supervisor(Slack.Bot.Supervisor, [config, data], id: {bot, Slack.Bot.Supervisor})
      end)

    children = [registry_spec | bot_specs]

    children =
      if use_console?() do
        [supervisor(Slack.Console, []) | children]
      else
        children
      end

    supervise(children, strategy: :one_for_one)
  end

  defp use_console? do
    Application.get_env(:slack, :use_console, false)
  end

  def start_bot(%{} = config) do
    {config, data} = bot_config_to_spec(config)
    Slack.Bot.Supervisor.start_link(config, data)
  end

  def stop_bot(name) do
    Supervisor.stop(:"#{name}:supervisor")
  end

  defp bot_configs do
    defaults = forced_bot_config_values()

    :slack
    |> Application.get_env(:bots, [])
    |> Enum.map(&struct(Slack.Bot.Config, &1 |> Map.merge(defaults)))
  end

  defp forced_bot_config_values do
    if Application.get_env(:slack, :all_bots_use_console),
      do: %{socket_client: Slack.Console.Socket, api_client: Slack.Console.APIClient},
      else: %{}
  end

  defp bot_config_to_spec(conf) do
    bot_name = {conf.workspace, conf.name}
    api_data = Slack.Bot.Supervisor.init_api_calls(conf.api_client, conf.token, bot_name)
    {Map.put(conf, :name, bot_name), api_data}
  end
end
