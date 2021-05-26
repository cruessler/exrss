defmodule ExRss.DateParser do
  import Ecto.Query

  alias Ecto.Changeset
  alias ExRss.Entry
  alias ExRss.Repo

  def list_unparsed(number) do
    from(e in Entry, where: is_nil(e.posted_at) and not is_nil(e.raw_posted_at), limit: ^number)
    |> Repo.all()
  end

  def clear_parsed() do
    Entry
    |> Repo.update_all(set: [posted_at: nil])
  end

  def parse() do
    from(e in Entry, where: is_nil(e.posted_at) and not is_nil(e.raw_posted_at))
    |> Repo.all()
    |> Enum.reduce({0, 0}, fn entry, {successes, errors} ->
      case Entry.parse_time(entry.raw_posted_at) do
        {:ok, parsed_time} ->
          entry
          |> Changeset.change(posted_at: parsed_time)
          |> Repo.update!()

          {successes + 1, errors}

        {:error, _} ->
          {successes, errors + 1}
      end
    end)
  end
end
