defmodule DexyPluginHTTP do

  @app :dexy_plugin_kv
  @adapter Application.get_env(@app, __MODULE__)[:adapter]
    || __MODULE__.Adapter.HTTPoison

  defmodule Adapter do
    @type error :: {:error, reason}
    @type reason :: term
    @type result :: {:ok, term} | error
    @type uri :: bitstring
    @type method :: bitstring
    @type opts :: Keywords.t

    @callback request(uri, method, opts) :: result
  end

  use DexyLib, as: Lib

  def on_call state = %{fun: fun} do
    {state, fun}
  end

end
