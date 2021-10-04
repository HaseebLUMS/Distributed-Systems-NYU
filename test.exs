defmodule TraceSimulator do
  import Kernel,
    except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]
  import Emulation, only: [spawn: 2, send: 2]

  defp update_combine_and_update_time(signature, time, rcvd_time) do
    time = TimeLab.update_vector_clock(signature, time)
    time = TimeLab.combine_vector_clocks(time, rcvd_time)
    time = TimeLab.update_vector_clock(signature, time)
    time
  end

  def client(signature, time, driver) do
    receive do
      {:send, target, rcvd_time} ->
        time = update_combine_and_update_time(signature, time, rcvd_time)
        send(target, {:report_time_to_driver, time})
        client(signature, time, driver)
      {:report_time_to_driver, rcvd_time} ->
        time = update_combine_and_update_time(signature, time, rcvd_time)
        send(driver, {:report, time})
      _ -> raise "Unexpected Message Received"
    end
  end

  def driver() do
    me = self()
    default_time = %{client_1: 0, client_2: 0, client_3: 0}
    spawn(:client_1, fn -> client(:client_1, default_time, me) end)
    spawn(:client_2, fn -> client(:client_2, default_time, me) end)
    spawn(:client_3, fn -> client(:client_3, default_time, me) end)

    send(:client_1, {:client_2, default_time})
    send(:client_1, {:client_3, default_time})

    driver_helper()
  end

  defp driver_helper() do
    receive do
      {:report, time} ->
        IO.puts(time)
        driver_helper()
      _ -> raise("Unexpected mssoge")
    end
  end
end

TraceSimulator.driver()