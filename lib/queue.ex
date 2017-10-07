defmodule Queue do
  @moduledoc """
  blocking FIFO queue agent (wrapper around erlang's :queue
  """

  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  @impl true
  def init(_arg) do
    {:ok, {:queue.new(), :queue.new()}}
  end

  def push(q, val) do
    GenServer.call(q, {:push, val})
  end

  def pop(q, timeout \\ :infinity) do
    case GenServer.call(q, :pop, timeout) do
      {:ok, val} -> val
      {:wait, ref} ->
        receive do
          {^ref, val} -> val
        after
          timeout -> unregister_waiter(q, ref)
                     {:error, :timeout}
        end
    end
  end

  def unregister_waiter(q, ref) do
    GenServer.call(q, {:unregister_waiter, ref})
  end

  @impl true
  def handle_call({:unregister_waiter, ref}, {pid, _}, {queue, waiters}) do
    # Filters on original call ref and same pid
    new_waiters = :queue.filter(fn
      {^pid, ^ref} -> false
      _ -> true end,
      waiters)
    {:reply, :ok, {queue, new_waiters}}
  end

  # Push, no one is waiting
  @impl true
  def handle_call({:push, val}, _from, {state, {[], []} = waiters}) do
    new_state = :queue.in(val, state)
    {:reply, :ok, {new_state, waiters}}
  end

  # Push, and notify first waiter
  @impl true
  def handle_call({:push, val}, _from, {state, waiters}) do
    {{:value, {pid, ref}}, new_waiters} = :queue.out(waiters)
    Process.send(pid, {ref, val}, [])
    {:reply, :ok, {state, new_waiters}}
  end

  @impl true
  def handle_call(:pop, from, {state, waiters}) do
    case :queue.out(state) do
      {{:value, val}, new_state} -> {:reply, {:ok, val}, {new_state, waiters}}
      {:empty, new_state} -> wait_for_value(from, {new_state, waiters})
    end
  end

  defp wait_for_value({_pid, ref} = from, {state, waiters}) do
    {:reply, {:wait, ref}, {state, :queue.in(from, waiters)}}
  end

  # NOTE: adding this as an additional push mechanism to support sending messages to
  # generic process in Slack.Console.PubSub (facilitates assert_receive tests)
  @impl true
  def handle_info({:push, val}, state) do
    {:reply, :ok, new_state} = handle_call({:push, val}, nil, state)
    {:noreply, new_state}
  end
end
