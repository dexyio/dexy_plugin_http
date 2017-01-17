defmodule DexyPluginHTTP.Adapters.HTTPoison do

  use DexyLib, as: Lib
  use HTTPoison.Base
  alias DexyPluginHTTP.Request

  @behaviour DexyPluginHTTP.Adapter

  def request req = %Request{} do
    request(
      method(req.method),
      req.url,
      req.body || "",
      (req.header || []) |> Enum.to_list,
      req.options || []
    ) |> case do
      {:ok, res} -> {:ok, response res}
      {:error, res} -> {:error, response res}
    end
  end

  defp method(method), do: do_method(method)

  defp do_method "get" do :get end
  defp do_method "put" do :put end
  defp do_method "post" do :post end
  defp do_method "patch" do :patch end
  defp do_method "delete" do :delete end
  defp do_method "options" do :options end
  defp do_method _ do :get end

  defp response res = %HTTPoison.Response{} do
    res = %{
      "code" => res.status_code,
      "body" => res.body,
      "header" => res.headers |> Enum.into(%{})
    }
    IO.inspect res
    res
  end

  defp response _res = %HTTPoison.Error{reason: reason} do
    reason |> inspect
  end

end
