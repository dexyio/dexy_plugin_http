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

  test "gun -> inspect_url!" do
    HTTP.Adapters.Gun.inspect_url!("http://www.exampl.com") |> IO.inspect
    HTTP.Adapters.Gun.inspect_url!("http://www.exampl.com/") |> IO.inspect
    HTTP.Adapters.Gun.inspect_url!("http://www.exampl.com:8080") |> IO.inspect
    HTTP.Adapters.Gun.inspect_url!("http://www.exampl.com:8080/") |> IO.inspect
    HTTP.Adapters.Gun.inspect_url!("https://www.exampl.com/a/b/c") |> IO.inspect
    HTTP.Adapters.Gun.inspect_url!("https://www.exampl.com:8888/a/b/c") |> IO.inspect
  end

  test "gun -> request" do
    req = %HTTP.Request{
      method: "put",
      url: "https://www.dexy.io/echo2/안녕하세요!",
      params: %{"foo"=>"bar", "body"=>"반갑습니다"},
      body: "Welcome to 한국"
    }
    res = HTTP.Adapters.Gun.request req
    IO.inspect res: res
  end

end
