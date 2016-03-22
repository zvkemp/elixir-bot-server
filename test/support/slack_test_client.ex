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
  defstruct [:host, :options, :incoming]

  def connect!(host, opts) do
    { :ok, agent } = Agent.start_link(fn -> [] end)
    %SocketTestClient{ host: host, options: opts, incoming: agent }
  end

  def recv(%{ incoming: pid } = socket) do
    :timer.sleep(5) # small artificial latency

    case Agent.get(pid, &List.first(&1)) do
      nil  -> recv(socket)
      data ->
        Agent.update(pid, fn ([_|xs]) -> xs end)
        { :ok, { :text, data }}
    end
  end

  def send!(%SocketTestClient{ options: opts, incoming: pid } = _socket, {:text, payload}) do
    "/" <> token = opts[:path]
    { :ok, json } = Poison.decode(payload)
    data  = { :test_payload, token, json }
    { :ok, reply } = %{ "reply_to" => json["id"] } |> Poison.encode

    # confirms receipt with the test process; allows assert_receive calls
    send(Process.whereis(:"RECV:#{token}"), data)
    Agent.update(pid, fn (xs) -> [reply|xs] end)
  end
end
