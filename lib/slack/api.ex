defmodule Slack.API do
  # @behaviour Slack.Behaviours.API
  use Slack.Behaviours.API

  @api_root "https://slack.com/api"
  @methods %{auth:         "rtm.start",
             channels:     "channels.list",
             groups:       "groups.list",
             join_channel: "channels.join",
             leave_channel: "channels.leave"}
  @json_headers ["Content-Type": "application/json", "Accepts": "application/json"]

  def auth_request(token, _internal_name \\ nil) do
    post_method(:auth, %{token: token})
  end

  def join_channel(channel_name, token) do
    post_method(:join_channel, %{token: token, name: channel_name})
  end

  def leave_channel(channel_id, token) do
    post_method(:leave_channel, %{token: token, channel: channel_id})
  end

  def list_channels(token) do
    post_method(:channels, %{token: token})
  end

  def list_groups(token) do
    post_method(:groups, %{token: token})
  end

  def _post(method, %{token: _} = query) do
    {:ok, json} = post("#{method}?#{URI.encode_query(query)}")
    json
  end

  defp post_method(method, %{token: _} = query) do
    {:ok, json} = post("#{@methods[method]}?#{URI.encode_query(query)}")
    json
  end

  defp post(path) do
    case HTTPotion.post("#{@api_root}/#{path}", [headers: @json_headers]) do
      %{status_code: 200, body: body} -> {:ok, Poison.decode!(body)}
      %{status_code: s}               -> {:error, s}
    end
  end
end
