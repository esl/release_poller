defmodule DockerApi do
  require Logger

  @version "v1.37"
  @endpoint URI.encode_www_form("/var/run/docker.sock")
  @protocol "http+unix"
  @url "#{@protocol}://#{@endpoint}/#{@version}"
  @json_header {"Content-Type", "application/json"}

  alias DockerApi.Tar

  def create_layer(payload, wait \\ false) do
    container_id = create_container(payload)

    new_image_id =
      container_id
      |> start_container()
      |> maybe_wait_container(wait)
      |> commit(%{})

    container_id
    |> stop_container()
    |> remove_container()

    new_image_id
  end

  def commit(container_id, payload) do
    {:ok, %{body: body, status_code: 201}} =
      HTTPoison.post("#{@url}/commit?container=#{container_id}", Poison.encode!(payload), [
        @json_header
      ])

    %{"Id" => image_id} = Poison.decode!(body)

    # ImageId comes in the form of sha256:IMGAGE_ID and the only part that we are
    # interested in is in the IMAGE_ID
    image_id =
      image_id
      |> String.slice(7..-1)

    Logger.info("image created #{image_id}")
    image_id
  end

  def create_container(payload, params \\ %{}) do
    name = Map.get(payload, "ContainerName", "")

    params = if name != "", do: Map.merge(params, %{name: name}), else: params

    {:ok, %{body: body, status_code: 201}} =
      "#{@url}/containers/create"
      |> URI.parse()
      |> Map.put(:query, URI.encode_query(params))
      |> URI.to_string()
      |> HTTPoison.post(Poison.encode!(payload), [@json_header])

    %{"Id" => container_id} = Poison.decode!(body)
    Logger.info("container created #{container_id}")
    container_id
  end

  def remove_container(container_id) do
    Logger.info("removing intermediate container #{container_id}")

    {:ok, %{status_code: 204}} = HTTPoison.delete("#{@url}/containers/#{container_id}")

    :ok
  end

  def start_container(container_id) do
    {:ok, %{status_code: 204}} =
      HTTPoison.post("#{@url}/containers/#{container_id}/start", "", [])

    container_id
  end

  def stop_container(container_id) do
    "#{@url}/containers/#{container_id}/stop"
    |> URI.parse()
    |> Map.put(:query, URI.encode_query(%{t: 5}))
    |> URI.to_string()
    |> HTTPoison.post("", [], timeout: 30_000, recv_timeout: 30_000)
    |> case do
      {:ok, %{status_code: status}} when status in [204, 304] -> container_id
      {:error, _} = error -> error
    end
  end

  def maybe_wait_container(container_id, true), do: wait_container(container_id)
  def maybe_wait_container(container_id, false), do: container_id

  def wait_container(container_id, timeout \\ :infinity) do
    {:ok, %{status_code: 200}} =
      HTTPoison.post("#{@url}/containers/#{container_id}/wait", "", [],
        timeout: timeout,
        recv_timeout: timeout
      )

    container_id
  end

  def upload_file(container_id, input_path, output_path) do
    final_path = Tar.tar(input_path, File.cwd!())
    archive_payload = File.read!(final_path)

    query_params =
      URI.encode_query(%{
        "path" => output_path,
        "noOverwriteDirNonDir" => false
      })

    {:ok, %{status_code: 200}} =
      "#{@url}/containers/#{container_id}/archive"
      |> URI.parse()
      |> Map.put(:query, query_params)
      |> URI.to_string()
      |> HTTPoison.put(archive_payload, [{"Content-Type", "application/tar"}])

    File.rm!(final_path)

    container_id
  end

  def pull(image) do
    Logger.info("pulling image #{image}")

    {:ok, %{status_code: 200}} =
      HTTPoison.post("#{@url}/images/create?fromImage=#{image}", "", [],
        timeout: :infinity,
        recv_timeout: :infinity
      )

    :ok
  end

  def create_volume(payload) do
    {:ok, %{status_code: 201}} =
      HTTPoison.post("#{@url}/volumes/create", Poison.encode!(payload), [@json_header])

    :ok
  end
end
