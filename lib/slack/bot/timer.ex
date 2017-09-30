defmodule Slack.Bot.Timer do
  # ping every x seconds
  # Usually `ref` will be Slack.Bot (controller server)
  def ping_fn(ref, sleep \\ 1000) do
    fn -> ping_stream(ref, sleep) end
  end

  defp ping_stream(ref, interval \\ 1000) do
    interval
    |> Stream.interval
    |> Stream.each(fn _ -> GenServer.cast(ref, :ping) end)
    |> Stream.run
  end
end
