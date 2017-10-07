defmodule Slack.Responders.Default do
  alias Slack.Bot.Config
  def respond(name, %{"text" => t} = msg, %Config{} = config) do
    if contains_username?(t, [name, "<@#{config.id}>"]) do
      try_echo(name, msg, config)
    end
  end

  def respond(_, _, _) do
    nil
  end

  import Slack.Bot, only: [say: 3]

  defp try_echo(name, %{"text" => t, "user" => _user, "channel" => c}, %Config{} = config) do
    mention = "<@#{config.id}>"
    if String.starts_with?(t, "#{name} echo ") || String.starts_with?(t, "#{mention} echo ") do
      say(name, t |> String.split(" echo ", parts: 2) |> Enum.at(1), c)
    else
      say(name, config.ribbit_msg, c)
    end
  end
  defp try_echo(_, _, _), do: nil

  defp contains_username?(msg, names) do
    Enum.any?(names, &(String.contains?(msg, &1)))
  end
end
