defmodule Slack.Responders.Default do
  def respond(name, %{ "text" => t } = msg, %{ id: uid } = config) do
    cond do
      contains_username?(t, [name, "<@#{uid}>"]) ->
        try_echo(name, msg, config)
      true -> nil
    end
  end

  def respond(_, _, _) do
    nil
  end

  import Slack.Bot, only: [say: 3]

  defp try_echo(name, %{ "text" => t, "user" => user, "channel" => c }, %{ id: uid, ribbit_msg: r }) do
    mention = "<@#{uid}>"
    cond do
      String.starts_with?(t, "#{name} echo ") || String.starts_with?(t, "#{mention} echo ") ->
        say(name, String.split(t, " echo ", parts: 2) |> Enum.at(1), c)
      true -> say(name, r, c)
    end
  end
  defp try_echo(_, _, _), do: nil

  defp contains_username?(msg, names) do
    Enum.any?(names, &(String.contains?(msg, &1)))
  end
end
