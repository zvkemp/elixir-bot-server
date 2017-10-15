defmodule Slack.BotRegistry do
  @doc """
  wrap a name, role pair in a via tuple
  """
  def registry_key({ws, _n} = name, role) when is_binary(ws) do
    {:via, Registry, {__MODULE__, {name, role}}}
  end

  def lookup(key) do
    __MODULE__
    |> Registry.lookup(key)
    |> List.first()
  end
end
