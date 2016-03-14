defmodule Slack.Websocket do
  def connect!(token) do
    Slack.API.auth_request(token)["url"] |> connect
  end

  def connect_with_meta!(token) do
    auth = Slack.API.auth_request(token)
    socket = auth["url"] |> connect
    { socket, auth }
  end

  def connect(url) do
    %{ host: host, path: path } = URI.parse(url)
    Socket.Web.connect!(host, path: path, secure: true)
  end

  def send_payload(socket, payload) do
    # IO.puts(" <  #{payload |> inspect}")
    socket |> Socket.Web.send!({ :text, Poison.encode!(payload) })
  end

  def recv(socket) do
    response = socket |> Socket.Web.recv
    # IO.puts("  > #{response |> inspect}")
    case response do
      { :ok, { :text, body } } -> Poison.decode!(body)
      { :ok, { :ping, _    } } -> { :ping }
      e -> raise "Something went wrong: #{inspect e}"
    end
  end
end
