defmodule DexyPluginHTTPTest do
  use ExUnit.Case
  alias DexyPluginHTTP, as: HTTP
  doctest DexyPluginHTTP

  test "get" do
    assert {_state, %{"code"=>200}} = HTTP.get(%{args: ["http://www.example.com"], opts: %{}})
  end

  test "post" do
    assert {_state, %{"code"=>200}} = HTTP.post(%{args: ["http://www.example.com"], opts: %{}})
  end

  test "response" do
    {_, res} = HTTP.response(%{args: ["foo"], opts: %{"code"=>201}})
    assert res == %{"code" => 201, "body" => "foo", "header" => nil}
  end

end
