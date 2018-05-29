defmodule MqttStresser do
  use GenServer

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: :mqtt_stresser)
  end

  def init(state) do
    MqttStresser.SendMqtt.init()
    {:ok, counter} = Agent.start(fn -> 0 end)
    Process.register(counter, :counter)
    {:ok, state}
  end

  def stress(count) do
    IO.puts("Sending #{inspect(count)} mqtt messages.")
    Enum.each(1..count, fn(x) -> execute_stress(x) end)

    IO.puts("Done.")
  end

  def execute_stress(_) do
    spawn(fn -> MqttStresser.SendMqtt.send_dummy_message() end)
  end

  defmodule SendMqtt do
    use Hulaaki.Client

    def init() do
      {:ok, pid} = start_link(%{})
      Process.register(pid, :hulaaki_stresser)
      connect_loop(pid)
      subscriptions = [topics: ["input/#"], qoses: [1]]
      subscribe(:hulaaki_stresser, subscriptions)
    end

    def on_subscribed_publish(_) do
      Agent.update(:counter, &(&1 + 1))
    end

    def send_dummy_message() do
      timestamp = DateTime.utc_now()
      measure_value = Enum.random(1900..3000) / 100

      :timer.sleep Enum.random(0..1000)

      publish(
        :hulaaki_stresser,
        topic: "dataservice/input",
        message:
          "{\"timestamp\": \"#{inspect(timestamp)}\",\"input_id\": \"bfcb9574-55f3-11e8-8474-b8f6b115ae49\",\"measure_value\": #{
            inspect(measure_value)
          }}",
        dup: 0,
        qos: 1,
        retain: 0
      )
    end

    def connect_loop(pid) do
      mqtt_connection_string = Application.get_env(:mqtt_stresser, MqttStresser)
      conn = connect(pid, mqtt_connection_string)

      case conn do
        :ok ->
          IO.puts("Connected to Publish Broker.")
          conn

        _ ->
          IO.puts(
            "Error: Unable to connect to Publish Broker @ #{inspect(mqtt_connection_string)}."
          )

          :timer.sleep(1000)
          connect_loop(pid)
      end
    end
  end
end
