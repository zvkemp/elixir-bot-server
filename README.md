[![Build Status](https://travis-ci.org/zvkemp/elixir-bot-server.svg?branch=master)](https://travis-ci.org/zvkemp/elixir-bot-server)

# Slack Bot Server

Work-in-progress multi-bot server for Slack. Each bot starts its own supervision tree with a number of workers to handle
message receipt tracking, pings, and websocket client connections.

A small number of Slack API methods are also present.

## Installation

Clone the repo, modify the example config, and run `iex -S mix`. `Slack.start_bot("botname")` starts the bot, or uncomment
the `mod` line in `mix.exs` to start all bots on run.

#### New, as of 0.2: 

You can now configure a bot like this:

```elixir
config :slack,
  use_console: true, # starts the console supervisor
  default_channel: "console",
  bots: [
    %{name:    "frogbot",
      token:   "fake-token-obvs",
      ribbit_msg: "ribbit",
      responder: Slack.Bot.DefaultResponder,
      keywords: %{ "hello" => "Hey there!" },
      socket_client: Slack.Console.Socket,
      api_client: Slack.Console.APIClient
    }
  ]
```

The `Console` modules are intended to simulate a local slack channel running inside `iex`, which is useful for developing responder modules.

To send a message as a regular 'user', use `Slack.Console.say/1`. Note that bots need to be configured individually to use the console clients (otherwise they will attempt to post to slack).
Other than network latency, all other behavior conforms to real-life, including ping scheduling and deferral, rate limiting, and reply counting.

## Work In Progress:

- Pluggable response modules (currently they don't do much out of the box; I have some experiments that I haven't yet committed to this repo).
