defmodule Slack do
  use Application

  def start(_type, _args) do
    Slack.Supervisor.start_link
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
    children = [
      supervisor(Registry, [[keys: :unique, name: Slack.BotRegistry]]),
      supervisor(Slack.BotDepot, [bot_configs()])
    ]

    children = if use_console?() do
      [supervisor(Slack.Console, [])|children]
    else
      children
    end

    supervise(children, strategy: :one_for_one)
  end

  defp use_console? do
    Application.get_env(:slack, :use_console, false)
  end

  # def start_bot(name) when is_binary(name) or is_atom(name) do
  #   config = bot_configs() |> Enum.find(fn (%{name: n}) -> n == name end)
  #   start_bot(config)
  # end

  # TODO: use normal supervisor handler
  def start_bot(%{} = config) do
    Slack.Bot.Supervisor.start_link(config)
  end

  def stop_bot(name) do
    Supervisor.stop(:"#{name}:supervisor")
  end

  defp bot_configs do
    :slack
    |> Application.get_env(:bots, [])
    |> Enum.map(&Map.merge(%Slack.Bot.Config{}, &1))
  end
end
