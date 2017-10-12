defmodule Slack.Responders.Default do
  alias Slack.Bot.Config
  require Logger
  @spec respond(Slack.Bot.bot_name, map, %Config{}) :: any
  def respond({_ws, uname} = name, %{"text" => t} = msg, %Config{} = config) do
    if contains_username?(t, [uname, "<@#{config.id}>"]) do
      try_echo(uname, msg, config)
    end
  end

  def respond(_, _, _) do
    nil
  end

  import Slack.Bot, only: [say: 3]

  defp try_echo(name, %{"text" => t, "user" => _user, "channel" => c}, %Config{} = config) do
    mention = "<@#{config.id}>"
    if String.starts_with?(t, "#{name} echo ") || String.starts_with?(t, "#{mention} echo ") do
      say(config.name, t |> String.split(" echo ", parts: 2) |> Enum.at(1), c)
    else
      say(config.name, config.ribbit_msg, c)
    end
  end
  defp try_echo(_, _, _), do: nil

  defp contains_username?(msg, names) do
    Enum.any?(names, &(String.contains?(msg, &1)))
  end
end
