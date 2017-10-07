use Mix.Config

config :slack,
  use_console: true,
  default_channel: "console",
  bots: [
    %{name: "toadbot",
      socket_client: Slack.Console.Socket,
      api_client: Slack.Console.APIClient,
      token: "toadbot-token",
      ribbit_msg: "croak",
      responder: Slack.Responders.Default
    }
  ]

config :logger, level: :debug
