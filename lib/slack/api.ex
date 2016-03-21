defmodule Slack.API do
  # @behaviour Slack.Behaviours.API
  use Slack.Behaviours.API

  @api_root "https://slack.com/api"
  @methods %{ auth:         "rtm.start",
              channels:     "channels.list",
              groups:       "groups.list",
              join_channel: "channels.join" }
  @json_headers ["Content-Type": "application/json", "Accepts": "application/json"]

  def auth_request(token) do
    post_method(:auth, %{ token: token })
  end

  def join_channel(channel_name, token) do
    post_method(:join_channel, %{ token: token, name: channel_name })
  end

  defp post_method(method, %{ token: _ } = query) do
    { :ok, json } = post("#{@methods[method]}?#{URI.encode_query(query)}")
    json
  end

  defp post(path) do
    case HTTPotion.post("#{@api_root}/#{path}", [headers: @json_headers]) do
      %{ status_code: 200, body: body } -> { :ok, Poison.decode!(body) }
      %{ status_code: s }               -> { :error, s }
    end
  end
end
