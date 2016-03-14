defmodule Slack.API do
  @api_root "https://slack.com/api"
  @methods %{ auth:         "rtm.start",
              channels:     "channels.list",
              groups:       "groups.list",
              join_channel: "channels.join" }
  @json_headers ["Content-Type": "application/json", "Accepts": "application/json"]

  def auth_request(token) do
    { :ok, json } = post("#{@methods.auth}?token=#{token}")
    json
  end

  def join_channel(token, channel_name) do
    { :ok, json } = post("#{@methods.join_channel}?token=#{token}&name=#{channel_name}")
    json
  end

  defp post(path) do
    case HTTPotion.post("#{@api_root}/#{path}", [headers: @json_headers]) do
      %{ status_code: 200, body: body } -> { :ok, Poison.decode!(body) }
      %{ status_code: s }               -> { :error, s }
    end
  end
end
