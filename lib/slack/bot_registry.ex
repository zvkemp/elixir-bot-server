defmodule Slack.BotRegistry do
  @doc """
  wrap a name, role pair in a via tuple
  """
  def registry_key({ws, _n} = name, role) when is_binary(ws) do
    {:via, Registry, {__MODULE__, {name, role}}}
  end

  def lookup(key) do
    Registry.lookup(__MODULE__, key) |> List.first
  end
end
