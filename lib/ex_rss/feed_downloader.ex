defmodule ExRss.FeedDownloader do
  alias Ecto.UUID

  def download_feeds(feeds, directory) do
    for %{title: title, url: url} <- feeds do
      Mix.shell().info(~s(Downloading "#{title}" #{url} …))

      with uri = URI.parse(url),
           %URI{authority: authority} when not is_nil(authority) <- uri,
           {:ok, response} <- HTTPoison.get(uri, [], follow_redirect: true),
           200 <- response.status_code,
           body = response.body do
        uuid = UUID.generate()
        path = Path.join(directory, "#{uuid}.xml")

        Mix.shell().info("Saving feed to #{path} …")

        File.write!(path, body)
      end
    end
  end
end
