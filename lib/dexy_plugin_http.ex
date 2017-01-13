defmodule DexyPluginHTTP do

  @app :dexy_plugin_kv
  @adapter Application.get_env(@app, __MODULE__)[:adapter]
    || __MODULE__.Adapters.HTTPoison

  defmodule Request do
    @type url :: bitstring
    @type body :: bitstring
    @type method :: bitstring
    @type header :: Keyword.t | map
    @type opts :: Keyword.t

    defstruct url: "",
              body: "",
              method: "",
              header: %{},
              opts: []
  end

  defmodule Adapter do
    @type error :: {:error, reason}
    @type reason :: term
    @type result :: {:ok, term} | error

    @callback request(%DexyPluginHTTP.Request{}) :: result
  end

  use DexyLib, as: Lib

  def get state = %{args: []} do do_get state, data! state end
  def get state = %{args: [url]} do do_get state, url end

  defp do_get state = %{opts: opts}, url do
    %Request{url: url, method: "get", header: opts["header"] || []}
    |> @adapter.request |> case do
      {:ok, res} -> {state, res}
      {:error, reason} -> {state, %{"error" => reason}}
    end
  end

  def post state = %{args: []} do do_post state, data! state end
  def post state = %{args: [url]} do do_post state, url end

  defp do_post state = %{opts: opts}, url do
    put_or_post state, "post", url, opts
  end

  def put state = %{args: []} do do_put state, data! state end
  def put state = %{args: [url]} do do_put state, url end

  defp do_put state = %{opts: opts}, url do
    put_or_post state, "put", url, opts
  end

  defp put_or_post state, method, url, opts do
    %Request{
      method: method, url: url,
      body: opts["body"] || "",
      header: opts["header"] || []
    } |> @adapter.request |> case do
      {:ok, res} -> {state, res}
      {:error, reason} -> {state, %{"error" => reason}}
    end
  end

  def response state = %{args: []} do do_response state, data! state end
  def response state = %{args: [body]} do do_response state, body end

  defp do_response state = %{opts: opts}, body do
    data = %{
      "code" => opts["code"] || 200,
      "body" => body || "",
      "header" => opts["header"] || opts["headers"] 
    }
    {state, data}
  end

  defp data! %{mappy: map} do
    Lib.Mappy.val map, "data"
  end

end
