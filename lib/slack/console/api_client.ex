defmodule Slack.Console.APIClient do
  @behaviour Slack.Behaviours.API

  @impl true
  def auth_request(token, internal_name) do
    %{"self" => %{"id" => token}, "channels" => [], "url" => "user/#{internal_name}"}
  end

  @impl true
  def join_channel(_, _), do: %{}

  @impl true
  def list_channels(_), do: %{"channels" => []}
  @impl true
  def list_groups(_), do: %{"groups" => []}
end
