defmodule DexyPluginHTTP.Adapters.Gun do

  use DexyLib, as: Lib
  alias DexyPluginHTTP.Request
  require Logger

  defmodule URL do
    defstruct host: nil,
              port: nil,
              path: nil,
              query: nil
  end

  @app :dexy_plugin_kv
  @behaviour DexyPluginHTTP.Adapter
  @regex_url ~r"(https?):\/\/(.+?)(?::([0-9]+))?(?:(\/+.+?)\/*)?(?:\?(.*?))?[\/\?\s]*$"iu
  
  def request req = %Request{options: options} do
    url = %URL{host: host, port: port} = req.url |> inspect_url!
    IO.inspect req: req, url: url
    with \
      {:ok, {conn, _proto}} <- open_sync(host, port, options),
      stream_ref = do_request(conn, req, url),
      {:ok, res} <- await_response(conn, stream_ref, options),
      :ok <- close_gracefully conn
    do {:ok, res} else
      {:error, _error} = err -> err
    end
  end

  defp do_request conn, req, _url = %URL{path: path, query: query} do
    path_query = case req.params do
      nil -> path <> "?" <> query
      params -> path <> "?" <> (URI.encode_query params) <> query
    end
    headers = req.header |> Enum.to_list
    body = req.body || ""
    :gun.request conn, req.method, path_query, headers, body
  end

  defp makeup_response {status, headers, body} do
    {:ok, %{
      "code" => status,
      "header" => headers |> Enum.into(%{}),
      "body" => body
    }}
  end

  @default_conn_timeout 60_000
  @spec open_sync(list, pos_integer, Keyword.t) :: {:ok, {pid, term}} | {:error, term}

  defp open_sync host, port, options do
    conn_timeout = options[:conn_timeout] || @default_conn_timeout
    case :gun.open(host, port) do
      {:ok, pid} -> case :gun.await_up(pid, conn_timeout) do
        {:ok, proto} -> {:ok, {pid, proto}}
        {:error, _reason} = error -> close_gracefully pid; error
      end
    end
  end

  @default_recv_timeout 60_000

  defp await_response(conn, stream_ref, options)  do
    recv_timeout= options[:recv_timeout] || @default_recv_timeout
    case :gun.await(conn, stream_ref, recv_timeout) do
      {:response, :fin, status, headers} ->
        {status, headers, ""}
      {:response, :nofin, status, headers} ->
        {:ok, body} = :gun.await_body(conn, stream_ref)
        {status, headers, body}
    end
    |> makeup_response
  end

  @spec close_gracefully(pid) :: :ok | {:error, :not_found}

  defp close_gracefully conn_pid do
    :gun.shutdown conn_pid
  end

  def inspect_url! str do
    case Regex.run @regex_url, str do
      nil -> throw :invalid_url
      [_, proto, host] -> {proto, host, "", "", ""}
      [_, proto, host, port] -> {proto, host, port, "", ""}
      [_, proto, host, port, path] -> {proto, host, port, path, ""}
      [_, proto, host, port, path, query] -> {proto, host, port, path, query}
    end
    |> do_inspect_url
  end

  defp do_inspect_url {proto, host, port, path, query} do
    %URL{
      host: host |> String.to_charlist,
      port: inspect_port!(port, proto),
      path: path == "" && "/" || URI.encode(path),
      query: query |> URI.encode
    }
  end

  defp inspect_port! port, proto do
    case proto do
      "http" -> port == "" && 80 || String.to_integer(port)
      "https" -> port == "" && 443 || String.to_integer(port)
    end
  end

end
