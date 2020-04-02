defmodule QueueTest do
  use ExUnit.Case
  doctest Queue

  test "basic sync usage" do
    {:ok, q} = Queue.start_link()

    Queue.push(q, 1)
    Queue.push(q, 2)
    Queue.push(q, 3)
    assert Queue.pop(q) == 1
    assert Queue.pop(q) == 2
    Queue.push(q, 4)
    assert Queue.pop(q) == 3
    assert Queue.pop(q) == 4
  end

  test "with infinite pop timeout" do
    {:ok, q} = Queue.start_link()

    spawn(fn ->
      Process.sleep(200)
      Queue.push(q, :foo)
    end)

    assert Queue.pop(q) == :foo
  end

  test "messages are preserved on pop timeout" do
    {:ok, q} = Queue.start_link()

    spawn(fn ->
      Process.sleep(300)
      Queue.push(q, :foo)
    end)

    assert Queue.pop(q, 50) == {:error, :timeout}
    assert Queue.pop(q, 50) == {:error, :timeout}
    assert Queue.pop(q, 50) == {:error, :timeout}
    assert Queue.pop(q, 500) == :foo
  end
end
