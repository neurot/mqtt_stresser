defmodule MqttStresserTest do
  use ExUnit.Case
  doctest MqttStresser

  test "greets the world" do
    assert MqttStresser.hello() == :world
  end
end
