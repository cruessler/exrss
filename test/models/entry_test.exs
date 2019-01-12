defmodule ExRss.EntryTest do
  use ExRss.ModelCase

  alias ExRss.Entry

  test "parses time" do
    assert {:ok, _} = Entry.parse_time("Tue, 03 Jan 2017 14:55:00 +0100")
    assert {:ok, _} = Entry.parse_time("Sun, 13 Nov 2016 21:00:00 GMT")
    assert {:ok, _} = Entry.parse_time("2018-01-13T19:05:08+00:00")
    assert {:ok, _} = Entry.parse_time("13 Mar 2018 00:00:00 GMT")
    assert {:ok, _} = Entry.parse_time("2018-08-22T10:07:06.121Z")
  end

  test "returns absolute link" do
    assert "http://example.com/posts/2018/12/26/1.html" =
             Entry.url_for("http://example.com", "/posts/2018/12/26/1.html")

    assert "https://example.com/posts/2018/12/26/1.html" =
             Entry.url_for("https://example.com", "/posts/2018/12/26/1.html")

    assert "http://example.com/posts/2018/12/26/1.html" =
             Entry.url_for("http://example.com", "posts/2018/12/26/1.html")

    assert "http://example.com/posts/2018/12/26/1.html" =
             Entry.url_for("http://example.com", "http://example.com/posts/2018/12/26/1.html")

    assert "http://example.com/2018/12/26/1.html" =
             Entry.url_for("http://example.com/posts", "/2018/12/26/1.html")
  end
end
