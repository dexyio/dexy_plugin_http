defmodule DexyPluginHTTP do

  @app :dexy_plugin_kv
  @adapter Application.get_env(@app, __MODULE__)[:adapter]
    || Logger.warn(
      "adapter not configured, default: #{__MODULE__.Adapters.HTTPoison}");
      __MODULE__.Adapters.HTTPoison

  defmodule Request do
    @type url :: bitstring
    @type body :: bitstring
    @type method :: bitstring
    @type header :: Keyword.t | map
    @type opts :: Keyword.t

    defstruct url: "",
              body: "",
              method: "",
              header: [],
              params: nil,
              options: []
  end

  defmodule Adapter do
    @type error :: {:error, reason}
    @type reason :: term
    @type result :: {:ok, term} | error

    @callback request(%DexyPluginHTTP.Request{}) :: result
  end

  use DexyLib, as: Lib

  deferror Error.InvalidArgument
  deferror Error.InvalidOptions

  def on_call state = %{args: []} do do_on_call state, data! state end
  def on_call state = %{args: [url]} do do_on_call state, url end

  defp do_on_call(state = %{fun: fun}, url) when is_bitstring(url) do
    method = case String.split fun, ".", parts: 2 do
      [fun] -> fun
      [_app, fun] -> fun
    end
    do_request state, url, method
  end

  defp do_on_call state, url do
    raise Error.InvalidArgument, reason: url, state: state
  end

  defp do_request state, url, method do
    req_struct(url, method, state) |> @adapter.request |> case do
      {:ok, res} -> {state, res}
      {:error, reason} -> do_response %{state | opts: %{"code" => 400}}, reason
    end
  end

  defp req_struct url, method, state = %{opts: opts} do
    %Request{
      url: url,
      method: method,
      body: opts["body"],
      header: opts["header"], 
      params: opts["params"],
      options: req_options(opts, state)
    }
  end

  @default_timeout 5_000
  defp req_options opts, state do
    (timeout = opts["timeout"] || @default_timeout) && (timeout > 0 and timeout <= 60_000)
      || raise Error.InvalidOptions, reason: %{timeout: timeout}, state: state
    (qs_params = opts["params"] || %{}) && is_map(qs_params)
      || raise Error.InvalidOptions, reason: %{params: qs_params}, state: state
    [
      recv_timeout: timeout,
      params: qs_params 
    ]
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
