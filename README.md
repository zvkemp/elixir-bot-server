[![Build Status](https://travis-ci.org/zvkemp/elixir-bot-server.svg?branch=master)](https://travis-ci.org/zvkemp/elixir-bot-server)

# Slack Bot Server

Multi-bot server frameworkk for Slack. See [zvkemp/frog_and_toad](https://github.com/zvkemp/frog_and_toad) for an implementation example.

- Run multiple bots in a single VM, with server-side interaction and coordinated replies
- Run the same bots on multiple workspaces

## Installation

Clone the repo, modify the example config, and run `iex -S mix`.
the `mod` line in `mix.exs` to start all bots on run.

You can configure a bot like this:

```elixir
config :slack,
  use_console: true, # simulate a local slack instance
  print_to_console: true, # print console messages to the local tty (disabled in test)
  default_channel: "CHANNELID",
  bots: [
    %{name: "frogbot",
      workspace: "frog-and-toad",
      socket_client: Slack.Console.Socket, # Remove this line to test with a real Slack channel
      api_client: Slack.Console.APIClient, # Remove this line to test with a real Slack channel
      token: "frogbot-local-token", # Replace with real API token
      ribbit_msg: "ribbit",
      responder: Slack.Responders.Default
    }
  ]
```

## Components

Each bot maintains its own supervision tree, comprised of the following servers:

- `Slack.Bot.Supervisor`
  - `Slack.Bot` - provides the main interface to control the bot's responses
  - `Slack.Bot.Socket` - coordinates data transfer over the socket (either a websocket or the dev/test console queue)
  - `Slack.Bot.MessageTracker` - tracks sent messages and acknowledges receipts from the remote end. Sends a ping if no messages have been sent for 10 seconds.
  - `Slack.Bot.Outbox` - rate-limiter for outgoing messages

Each bot process is registered using via tuples in the form of `{:via, Slack.BotRegistry, {"name", role_module}}`, where `role_module` is one of the above genserver modules.

The `Console` modules are intended to simulate a local slack channel running inside `iex`, which is useful for developing responder modules. In the config:

```elixir
use_console: true, # starts the Slack.Console supervision tree
print_to_console: true # print console messages to the local terminal
```

Use `Slack.console.say({"workspace_name", "channel_name", "message here"})` to act as a non-bot (human?) user.

Other than network latency, all other behavior conforms to real-life, including ping scheduling and deferral, rate limiting, and reply counting.

## Responders

Customization is done via the `responder: Slack.Responders.Default` config. For an example of a more robust responder, see [the responder from zvkemp/frog_and_toad](https://github.com/zvkemp/frog_and_toad/blob/master/lib/frog_and_toad/responder.ex).

## Work In Progress:

- Implement a Responder behaviour
