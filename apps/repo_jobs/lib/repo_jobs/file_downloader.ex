defmodule RepoJobs.FileDownloader do
  def download(url, headers \\ []) do
    request(
      url,
      headers,
      recv_timeout: 10_000,
      connect_timeout: 10_000,
      timeout: 10_000
    )
  end

  defp request(uri, headers, options) do
    case HTTPoison.get(uri, headers, options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, :not_found}

      {:ok, %HTTPoison.Response{status_code: _} = response} ->
        {:error, response}

      {:error, %HTTPoison.Error{reason: :timeout}} ->
        {:error, :timeout}

      {:error, response} ->
        {:error, response}
    end
  end
end
