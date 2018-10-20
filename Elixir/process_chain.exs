defmodule ProcessChain do
  @doc """
  Starts a chain of n processes that will count upwards by forwarding their
  incremented counter to the next process in the chain.
  """
  def start(n) do
    pids = Enum.reduce(1..n, [], fn id, pids ->
      nextpid = List.first(pids)
      pid = spawn(fn -> worker(id, n, nextpid) end)
      [pid|pids]
    end)

    # Set up the last pid to send their counter back to us.
    pids
    |> List.last
    |> send({:setnext, self()})

    # Begin the message chain
    pids
    |> List.first
    |> send({:count, 0})

    # Wait to hear back from the last pid
    receive do
      {:count, ^n} -> {:ok, n}
    end
  end

  defp worker(n, max, nextpid) do
    receive do
      {:setnext, next} ->
        worker(n, max, next)
      {:count, n} ->
        send(nextpid, {:count, n + 1})
    end
  end
end

{:ok, count} = ProcessChain.start(10)
IO.puts "Done! (count=#{count})"
