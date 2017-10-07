defmodule Slack.BotRegistry do
  @doc """
  wrap a name, role pair in a via tuple
  """
  def registry_key(name, role) do
    {:via, Registry, {__MODULE__, {name, role}}}
  end

  @doc """
  Given a role key, get a different role key for the same bot
  """
  def key_for_role({:via, Registry, {__MODULE__, {name, _}}}, role) do
    registry_key(name, role)
  end
end

defmodule Slack.BotDepot do
  @moduledoc """
  Starts a supervisor for each bot in configs
  """

  use Supervisor

  def start_link(configs) do
    Supervisor.start_link(__MODULE__, configs, name: __MODULE__)
  end

  def init(configs) do
    children = configs |> Enum.map(fn (%{name: name} = config) ->
      supervisor(Slack.Bot.Supervisor, [config], id: :"registered:#{name}")
    end)

    supervise(children, strategy: :one_for_one)
  end
end
