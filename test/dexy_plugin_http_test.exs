defmodule DexyPluginHTTPTest do
  use ExUnit.Case
  alias DexyPluginHTTP, as: HTTP
  doctest DexyPluginHTTP

  @test_url "http://www.dexy.io/echo"
  @opts %{"timeout" => 10_000, "body" => "hello", "params" => %{"foo"=>"bar"}}

  test "get" do
    state = %{fun: "http.get", args: [@test_url], opts: @opts}
    assert {_state, %{"code"=>200}} = HTTP.on_call(state)
  end

  test "put" do
    state = %{fun: "http.put", args: [@test_url], opts: @opts}
    assert {_state, %{"code"=>200}} = HTTP.on_call(state)
  end

  test "post" do
    state = %{fun: "http.post", args: [@test_url], opts: @opts}
    assert {_state, %{"code"=>200}} = HTTP.on_call(state)
  end

  test "response" do
    {_, res} = HTTP.response(%{args: ["foo"], opts: %{"code"=>201}})
    assert res == %{"code" => 201, "body" => "foo", "header" => nil}
  end

end
