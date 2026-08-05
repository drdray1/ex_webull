defmodule ExWebull.Mqtt.ConnectionStartTest do
  @moduledoc """
  Exercises `start_link/1` and the client API against a mocked
  `Tortoise311.Connection`, so no socket is opened.

  Mimic runs in global mode here because the GenServer calls Tortoise
  from its own process; that requires `async: false`.
  """
  use ExUnit.Case, async: false
  use Mimic

  alias ExWebull.Mqtt.Connection

  setup :set_mimic_global

  setup do
    stub(Tortoise311.Connection, :start_link, fn _opts ->
      {:ok, spawn(fn -> Process.sleep(:infinity) end)}
    end)

    stub(Tortoise311.Connection, :subscribe, fn _cid, _topic, _opts -> :ok end)
    stub(Tortoise311.Connection, :unsubscribe, fn _cid, _topic -> :ok end)
    :ok
  end

  defp capture_connect_opts do
    test = self()

    expect(Tortoise311.Connection, :start_link, fn opts ->
      send(test, {:connect_opts, opts})
      {:ok, spawn(fn -> Process.sleep(:infinity) end)}
    end)
  end

  test "start_link/1 connects with the session id as client id and app key as username" do
    capture_connect_opts()

    {:ok, conn} =
      Connection.start_link(app_key: "ak", session_id: "sess-1", subscribers: [self()])

    assert_receive {:connect_opts, opts}
    assert opts[:client_id] == "sess-1"
    assert opts[:user_name] == "ak"
    assert {Tortoise311.Transport.Tcp, server} = opts[:server]
    assert server[:host] == ~c"data-api.webull.com"
    assert server[:port] == 1883

    assert Connection.session_id(conn) == "sess-1"
    Connection.stop(conn)
  end

  test "start_link/1 generates a session id when none is given" do
    {:ok, conn} = Connection.start_link(app_key: "ak")

    session_id = Connection.session_id(conn)
    assert session_id =~ ~r/^[0-9a-f]{32}$/

    Connection.stop(conn)
  end

  test "start_link/1 honours host, port and an SSL transport" do
    capture_connect_opts()

    {:ok, conn} =
      Connection.start_link(
        app_key: "ak",
        session_id: "sess-ssl",
        host: "mqtt.example.test",
        port: 8883,
        transport: Tortoise311.Transport.SSL
      )

    assert_receive {:connect_opts, opts}
    assert {Tortoise311.Transport.SSL, server} = opts[:server]
    assert server[:host] == ~c"mqtt.example.test"
    assert server[:port] == 8883
    assert server[:verify] == :verify_none

    Connection.stop(conn)
  end

  test "start_link/1 accepts a :name and stops on connect failure" do
    name = :"mqtt_named_#{System.unique_integer([:positive])}"
    {:ok, _conn} = Connection.start_link(app_key: "ak", session_id: "sess-n", name: name)
    assert Connection.session_id(name) == "sess-n"
    Connection.stop(name)

    expect(Tortoise311.Connection, :start_link, fn _opts -> {:error, :econnrefused} end)
    Process.flag(:trap_exit, true)

    assert {:error, {:mqtt_connect_failed, :econnrefused}} =
             Connection.start_link(app_key: "ak", session_id: "sess-fail")
  end

  test "subscribe_topic/2 and unsubscribe_topic/2 wrap single topics" do
    test = self()

    expect(Tortoise311.Connection, :subscribe, 2, fn cid, topic, qos: 0 ->
      send(test, {:sub, cid, topic})
      :ok
    end)

    expect(Tortoise311.Connection, :unsubscribe, fn cid, topic ->
      send(test, {:unsub, cid, topic})
      :ok
    end)

    {:ok, conn} = Connection.start_link(app_key: "ak", session_id: "sess-t")

    assert :ok = Connection.subscribe_topic(conn, "snapshot")
    assert_receive {:sub, "sess-t", "snapshot"}

    assert :ok = Connection.subscribe_topic(conn, ["tick"])
    assert_receive {:sub, "sess-t", "tick"}

    assert :ok = Connection.unsubscribe_topic(conn, "tick")
    assert_receive {:unsub, "sess-t", "tick"}

    Connection.stop(conn)
  end

  test "add_subscriber/2 and remove_subscriber/2 control the fanout" do
    {:ok, conn} = Connection.start_link(app_key: "ak", session_id: "sess-s")

    assert :ok = Connection.add_subscriber(conn)
    assert :ok = Connection.remove_subscriber(conn)

    Connection.stop(conn)
  end
end
