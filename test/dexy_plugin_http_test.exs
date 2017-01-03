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
end
