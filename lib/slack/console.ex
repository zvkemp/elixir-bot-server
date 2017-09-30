defmodule Slack.Console do
  @moduledoc """
  Simulate a slack instance locally
  """
  use Supervisor

  def init(_args) do
    Supervisor.init([
      {Slack.Console.PubSub, []}
    ], strategy: :one_for_one)
  end

  def start_link do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end
end

defmodule Slack.Console.PubSub do
  use GenServer

  def child_spec(_args) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, []}, restart: :permanent, shutdown: 5000, type: :worker}
  end

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def subscribe(channel) do
  end

  def broadcast(channel) do
  end

  def handle_cast({:subscribe, channel}, from, state) do
  end
end

defmodule Slack.Console.Socket do
  @moduledoc """
  Stands in for slack websocket
  """
  use GenServer
  require Logger

  def connect!(_a, _b) do
    Logger.info("connect: #{[_a, _b] |> inspect}")
    {:fake_socket_for_logger}
  end

  def recv(socket) do
    Process.sleep(3000)
    Logger.info("receive #{self() |> inspect} #{socket |> inspect}")
    { :ok, { :ping, 100 }}
  end

  def send!(_socket, payload) do
    Logger.info("#{self() |> inspect} sending #{payload |> inspect}")
  end
end
