defmodule DexyPluginHTTPTest do
  use ExUnit.Case
  alias DexyPluginHTTP, as: HTTP
  doctest DexyPluginHTTP

  @test_url "http://www.dexy.io/echo"
  @opts %{"timeout" => 10_000, "body" => "hello", "params" => %{"foo"=>"bar"}}

  test "get" do
    state = %{fun: "http.get", args: [@test_url], opts: @opts}
    assert {_state, %{"code"=>code}} = HTTP.on_call(state)
    IO.inspect code: code
  end

  test "put" do
    state = %{fun: "http.put", args: [@test_url], opts: @opts}
    assert {_state, %{"code"=>code}} = HTTP.on_call(state)
    IO.inspect code: code
  end

  test "post" do
    state = %{fun: "http.post", args: [@test_url], opts: @opts}
    assert {_state, %{"code"=>code}} = HTTP.on_call(state)
    IO.inspect code: code
  end

  test "response" do
    {_, res} = HTTP.response(%{args: ["foo"], opts: %{"code"=>201}})
    assert res == %{"code" => 201, "body" => "foo", "header" => nil}
  end

  test "gun -> inspect_url!" do
    alias DexyPluginHTTP.Adapters.Gun
    assert %Gun.URL{host: 'www.exampl.com', path: "/", port: 80, query: ""}
      == Gun.inspect_url!("http://www.exampl.com")

    assert %Gun.URL{host: 'www.exampl.com', path: "/", port: 80, query: ""}
      == Gun.inspect_url!("http://www.exampl.com/")

    assert %Gun.URL{host: 'www.exampl.com', path: "/", port: 8080, query: ""}
      == Gun.inspect_url!("http://www.exampl.com:8080") 

    assert %Gun.URL{host: 'www.exampl.com', path: "/", port: 8080, query: ""}
      == Gun.inspect_url!("http://www.exampl.com:8080/")

    assert %Gun.URL{host: 'www.exampl.com', path: "/a/b/c", port: 443, query: ""}
      == Gun.inspect_url!("https://www.exampl.com/a/b/c") 

    assert %Gun.URL{host: 'www.exampl.com', path: "/a/b/c", port: 8888, query: ""}
      == HTTP.Adapters.Gun.inspect_url!("https://www.exampl.com:8888/a/b/c") 
  end

  test "gun -> request" do
    req = %HTTP.Request{
      method: "GET",
      url: "http://www.example.com",
    }
    assert {_, %{"code"=>code}} = HTTP.Adapters.Gun.request req
    IO.inspect code: code
  end

  test "gun -> server timeout" do
    req = %HTTP.Request{
      method: "GET",
      url: "http://www.example.com",
      options: %{
        conn_timeout: 100
      }
    }
    assert {:error, :timeout} == HTTP.Adapters.Gun.request req
  end

end
