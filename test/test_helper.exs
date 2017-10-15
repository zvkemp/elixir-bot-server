ExUnit.start()

defmodule TestHelpers do
  def new_bot_name do
    fn -> :crypto.strong_rand_bytes(16) end
    |> Stream.repeatedly
    |> Enum.take(2)
    |> List.to_tuple
  end

  @doc """
  proxies a subscription; forwards decoded JSON back to exunit for better
  pattern matching on messages
  """
  def subscribe_to_json(workspace, channel) do
    me = self()
    user_key = Base.encode64(:crypto.strong_rand_bytes(5))
    {:ok, pid} = TestMessageForwarder.start_as(
      {workspace, user_key},
      :json,
      fn {:push, json} -> Poison.decode!(json) end
    )
    Slack.Console.PubSub.subscribe(workspace, channel, pid, user_key)
  end
end

defmodule TestMessageForwarder do
  use GenServer
  import Slack.BotRegistry

  @spec start_as(Slack.Bot.bot_name, atom, function | nil) :: GenServer.on_start()
  def start_as(name, role, mapping_fun \\ default_mapping_fun) do
    start_link(registry_key(name, role), self(), role, mapping_fun)
  end

  @spec start_link(any, pid, atom, function) :: GenServer.on_start()
  def start_link(name, exunit, role, mapping_fun) do
    GenServer.start_link(__MODULE__, {exunit, role, mapping_fun}, name: name)
  end

  @impl true
  def init(config), do: {:ok, config}

  @impl true
  def handle_cast(msg, {exunit, role, mapping_fun} = config) do
    send(exunit, {role, mapping_fun.(msg)})
    {:noreply, config}
  end

  @impl true
  def handle_call(msg, _from, config) do
    GenServer.reply(_from, :ok)
    handle_cast(msg, config)
  end

  @impl true
  def handle_info(msg, config) do
    handle_cast(msg, config)
  end

  defp default_mapping_fun(), do: &(&1)
end
