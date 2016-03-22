defmodule SlackTestClient do
  use Slack.Behaviours.API

  def auth_request(token) do
    %{
       "url" => "ws://test.host/#{token}",
       "self" => %{ "id" => "ID#{token}" }
     }
  end

  def join_channel(channel_name, token) do
    %{}
  end
end

# See Bot Integration Tests
defmodule SocketTestClient do
  defstruct [:host, :options]

  def connect!(host, opts) do
    %SocketTestClient{ host: host, options: opts }
  end

  def recv(socket) do
    { :ok, { :text, "{}" } }
  end

  def send!(%SocketTestClient{ options: opts } = _socket, {:text, payload}) do
    "/" <> token = opts[:path]
    { :ok, json } = Poison.decode(payload)
    data = { :test_payload, token, json }
    send(Process.whereis(:"RECV:#{token}"), data)
  end
end
