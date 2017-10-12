use Mix.Config

config :slack,
  use_console: true,
  default_channel: "console",
  bots: (
    for {name, msg} <- [{"frogbot", "ribbit"}, {"toadbot", "croak"}, {"owlbot", "hoot"}],
        workspace <- ["workspace-a", "workspace-b"] do

      %{name: name,
        workspace: workspace,
        socket_client: Slack.Console.Socket,
        api_client: Slack.Console.APIClient,
        token: "#{name}-token-#{:crypto.strong_rand_bytes(6) |> Base.encode64}",
        ribbit_msg: "#{msg}-#{workspace}",
        responder: Slack.Responders.Default
      }
    end
  )

config :logger, level: :debug
