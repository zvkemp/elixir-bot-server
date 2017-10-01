defmodule Slack.Responders.Default do
  def respond(name, %{"text" => t} = msg, %{id: uid} = config) do
    if contains_username?(t, [name, "<@#{uid}>"]) do
      try_echo(name, msg, config)
    end
  end

  def respond(_, _, _) do
    nil
  end

  import Slack.Bot, only: [say: 3]

  defp try_echo(name, %{"text" => t, "user" => user, "channel" => c}, %{id: uid, ribbit_msg: r}) do
    mention = "<@#{uid}>"
    if String.starts_with?(t, "#{name} echo ") || String.starts_with?(t, "#{mention} echo ") do
      say(name, t |> String.split(" echo ", parts: 2) |> Enum.at(1), c)
    else
      say(name, r, c)
    end
  end
  defp try_echo(_, _, _), do: nil

  defp contains_username?(msg, names) do
    Enum.any?(names, &(String.contains?(msg, &1)))
  end
end
