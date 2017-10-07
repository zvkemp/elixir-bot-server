defmodule Slack.Behaviours.API do
  @callback auth_request(token :: binary(), internal_name :: binary() | nil) :: Map.t
  @callback join_channel(channel :: binary(), token :: String.t) :: Map.t
  @callback list_groups(token :: binary()) :: Map.t
  @callback list_channels(token :: binary()) :: Map.t

  defmacro __using__(_) do
    quote location: :keep do
      @behaviour Slack.Behaviours.API
    end
  end
end
