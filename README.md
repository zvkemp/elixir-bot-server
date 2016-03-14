# Slack Bot Server

Work-in-progress multi-bot server for Slack. Each bot starts its own supervision tree with a number of workers to handle
message receipt tracking, pings, and websocket client connections.

A small number of Slack API methods are also present.

## Installation

Clone the repo, modify the example config, and run `iex -S mix`. `Slack.start_bot("botname")` starts the bot, or uncomment
the `mod` line in `mix.exs` to start all bots on run.

## Work In Progress:

- Pluggable response modules (currently they don't do much out of the box; I have some experiments that I haven't yet committed to this repo).
