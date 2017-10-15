defmodule Slack.TestMessageForwarder do
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
