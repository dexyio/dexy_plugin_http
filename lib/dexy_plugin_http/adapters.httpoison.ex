defmodule DexyPluginHTTP.Adapters.HTTPoison do

  use DexyLib, as: Lib
  alias DexyPluginHTTP.Request

  @behaviour DexyPluginHTTP.Adapter

  def request req = %Request{method: "get"} do
    case HTTPoison.get req.url, req.header do
      {:ok, res} -> {:ok, response res}
      {:error, res} -> {:error, response res}
    end
  end

  def request req = %Request{method: "post"} do
    case HTTPoison.post req.url, req.body, req.header do
      {:ok, res} -> {:ok, response res}
      {:error, res} -> {:error, response res}
    end
  end

  def request req = %Request{method: "put"} do
    case HTTPoison.post req.url, req.body, req.header do
      {:ok, res} -> {:ok, response res}
      {:error, res} -> {:error, response res}
    end
  end

  defp response res = %HTTPoison.Response{} do
    %{
      "code" => res.status_code,
      "body" => res.body,
      "header" => res.headers |> Enum.into(%{})
    }
  end

  defp response _res = %HTTPoison.Error{reason: reason} do
    reason |> inspect
  end

end
