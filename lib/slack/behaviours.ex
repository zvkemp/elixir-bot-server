defmodule Slack.Behaviours.API do
  @callback auth_request(token :: String.t) :: Map.t
  @callback join_channel(channel :: String.t, token :: String.t) :: Map.t

  defmacro __using__(_) do
    quote location: :keep do
      @behaviour Slack.Behaviours.API
    end
  end
end
