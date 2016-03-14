defmodule Slack.BotRegistry do
  @moduledoc """
  Starts a supervisor for each bot in configs
  """

  use Supervisor

  def start_link(configs) do
    Supervisor.start_link(__MODULE__, { :ok, configs }, name: Slack.BotRegistry)
  end

  def init({ :ok, configs }) do
    children = configs |> Enum.map(fn (%{ name: name } = config) ->
      supervisor(Slack.Bot.Supervisor, [config], id: :"registered:#{name}")
    end)

    supervise(children, strategy: :one_for_one)
  end
end
