defmodule DexyPluginHTTP.Adapters.Gun do

  use DexyLib, as: Lib
  alias DexyPluginHTTP.Request

  defmodule URL do
    defstruct host: nil,
              port: nil,
              path: nil,
              query: nil
  end

  @app :dexy_plugin_kv
  @behaviour DexyPluginHTTP.Adapter
  @regex_url ~r"(https?):\/\/(.+?)(?::([0-9]+))?(?:(\/+.+?)\/*)?(?:\?(.*?))?[\/\?\s]*$"iu
  @default_conn_timeout 60_000
  @default_recv_timeout 60_000
  @conn_timeout Application.get_env(@app, :conn_timeout) || @default_conn_timeout
  @recv_timeout Application.get_env(@app, :recv_timeout) || @default_recv_timeout

  def request req = %Request{} do
    url = %URL{host: host, port: port} = req.url |> inspect_url!
    with \
      {:ok, {conn, _proto}} <- open_sync(host, port),
      stream_ref = do_request(conn, req, url),
      {:ok, res} <- await_response(conn, stream_ref),
      :ok <- close_gracefully conn
    do {:ok, res} else
      {:error, _error} = err -> err
    end
  end

  defp do_request conn, req, url = %URL{path: path, query: query} do
    path_query = case req.params do
      nil -> path <> "?" <> query
      params -> path <> "?" <> (URI.encode_query params) <> query
    end
    IO.inspect path: path, query: query, query: path_query
    :gun.request conn, req.method, path_query, Enum.to_list(req.header), req.body
  end

  defp await_response conn, stream_ref do
    case :gun.await(conn, stream_ref, @recv_timeout) do
      {:response, :fin, status, headers} ->
        {:ok, {status, Enum.into(headers, %{}), ""}}
      {:response, :nofin, status, headers} ->
        {:ok, body} = :gun.await_body(conn, stream_ref)
        IO.inspect body: body
        {:ok, {status, Enum.into(headers, %{}), body}}
    end
  end

  @spec open_sync(list, pos_integer) :: {:ok, {pid, term}} | {:error, term}

  defp open_sync host, port, timeout \\ @conn_timeout do
    case :gun.open(host, port) do
      {:ok, pid} -> case :gun.await_up(pid, timeout) do
        {:ok, proto} -> {:ok, {pid, proto}}
        {:error, _reason} = err -> close_gracefully pid; err
      end
    end
  end

  @spec close(pid) :: :ok | {:error, :not_found}

  defp close conn_pid do
    :gun.close conn_pid
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
      path: path |> URI.encode,
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
