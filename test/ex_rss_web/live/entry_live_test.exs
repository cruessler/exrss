defmodule ExRssWeb.EntryLiveTest do
  use ExRssWeb.ConnCase

  import Phoenix.LiveViewTest
  import ExRss.{AccountsFixtures, FeedFixtures}

  alias ExRss.{Feed, Repo}

  test "broadcasts updates when entry is marked as read", %{conn: conn} do
    user = user_fixture()
    feed = empty_feed_fixture(%{user_id: user.id})
    entry = entry_fixture(%{feed_id: feed.id})
    conn = log_in_user(conn, user)

    {:ok, lv1, _html1} = live(conn, ~p"/entries")
    {:ok, lv2, _html2} = live(conn, ~p"/entries")

    selector = "#entry-#{entry.id}"

    assert has_element?(lv1, selector)
    assert has_element?(lv2, selector)

    lv1
    |> element("#{selector} button[aria-label='Mark as read']")
    |> render_click()

    refute has_element?(lv1, selector)
    refute has_element?(lv2, selector)
  end

  defp empty_feed_fixture(%{user_id: user_id}) do
    Feed.changeset(%Feed{user_id: user_id, url: "https://example.com/blog"})
    |> Repo.insert!()
  end
end
