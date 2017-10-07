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
