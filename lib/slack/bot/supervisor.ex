defmodule Slack.Bot.Supervisor do
  use Supervisor

  def start_link(%{ name: name } = config) do
    Supervisor.start_link(__MODULE__, { :ok, config }, name: "#{name}:supervisor" |> String.to_atom)
  end

  # ---

  def init({ :ok, %{ name: name, token: token } = config }) do
    children = [
      worker(Slack.Bot,                    [:"#{name}:bot", config]),
      worker(Slack.Bot.Socket,             [:"#{name}:socket", token]),
      worker(Slack.Bot.Counter,            [:"#{name}:counter"]),
      worker(Slack.Bot.MessageTracker,     [:"#{name}:message_tracker"]),
      worker(Task,                         [Slack.Bot.Timer.ping_fn(:"#{name}:bot", 10000)], id: :ping_timer),
      # maybe this should be joined with Frog.Socket in another supervisor?
      worker(Task,                         [Slack.Bot.Receiver.recv_task(:"#{name}:bot", :"#{name}:socket")], id: :socket_receiver),
    ]

    supervise(children, strategy: :rest_for_one)
  end
end
