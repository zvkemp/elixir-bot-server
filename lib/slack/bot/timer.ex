defmodule Slack.Bot.Timer do
  # ping every x seconds
  # Usually `ref` will be Slack.Bot (controller server)
  def ping_fn(ref, sleep \\ 1000) do
    fn ->
      repeat(fn ->
        GenServer.cast(ref, { :ping })
      end, sleep)
    end
  end

  def repeat(function, sleep \\ 1000) do
    Stream.repeatedly(
      fn ->
        :timer.sleep(sleep)
        function.()
      end
    ) |> Stream.run
  end
end
