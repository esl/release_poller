defmodule DockerApi do
  @version "v1.37"
  @endpoint URI.encode_www_form("/var/run/docker.sock")
  @protocol "http+unix"

  alias DockerApi.Tar

  def commit(container_id, payload) do
    # commit image
    {:ok, %{body: body}} =
      HTTPoison.post(
        "#{@protocol}://#{@endpoint}/#{@version}/commit?container=#{container_id}",
        Poison.encode!(payload),
        [{"Content-Type", "application/json"}]
      )

    %{"Id" => image_id} = Poison.decode!(body)
    image_id
  end

  def create_container(payload, name) do
    {:ok, %{body: body}} =
      HTTPoison.post(
        "#{@protocol}://#{@endpoint}/#{@version}/containers/create?name=#{name}",
        Poison.encode!(payload),
        [{"Content-Type", "application/json"}]
      )

    %{"Id" => container_id} = Poison.decode!(body)
    container_id
  end

  def start_container(container_id) do
    {:ok, _} =
      HTTPoison.post(
        "#{@protocol}://#{@endpoint}/#{@version}/containers/#{container_id}/start",
        "",
        [
          {"Content-Type", "application/json"}
        ]
      )

    container_id
  end

  def wait_container(container_id) do
    {:ok, _} =
      HTTPoison.post(
        "#{@protocol}://#{@endpoint}/#{@version}/containers/#{container_id}/wait",
        "",
        [],
        timeout: :infinity,
        recv_timeout: :infinity
      )

    container_id
  end

  def upload_file(container_id, input_path, output_path) do
    final_path = Tar.tar(input_path, File.cwd!())
    archive_payload = File.read!(final_path)

    {:ok, _} =
      HTTPoison.put(
        "#{@protocol}://#{@endpoint}/#{@version}/containers/#{container_id}/archive?path=#{
          output_path
        }",
        archive_payload,
        [{"Content-Type", "application/tar"}]
      )

    :ok
  end

  def pull(image) do
    {:ok, _} =
      HTTPoison.post(
        "#{@protocol}://#{@endpoint}/#{@version}/images/create?fromImage=#{image}",
        "",
        []
      )

    :ok
  end
end
