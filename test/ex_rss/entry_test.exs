defmodule ExRss.EntryTest do
  use ExRss.DataCase

  alias ExRss.Entry

  test "parses time" do
    assert {:ok, _} = Entry.parse_time("Tue, 03 Jan 2017 14:55:00 +0100")
    assert {:ok, _} = Entry.parse_time("Wed, 8 Jan 2020 07:28:00 +0100")
    assert {:ok, _} = Entry.parse_time("Sun, 13 Nov 2016 21:00:00 GMT")
    assert {:ok, _} = Entry.parse_time("2018-01-13T19:05:08+00:00")
    assert {:ok, _} = Entry.parse_time("13 Mar 2018 00:00:00 GMT")
    assert {:ok, _} = Entry.parse_time("2018-08-22T10:07:06.121Z")
    assert {:ok, _} = Entry.parse_time("2020-05-03T13:10:00.000-06:00")
    assert {:ok, _} = Entry.parse_time("2019-01-17T00:00:00Z")
    assert {:ok, _} = Entry.parse_time("2022-07-09T15:00:00+0000")
    assert {:ok, _} = Entry.parse_time("06 Sep 2017 12:00 +0000")
    assert {:ok, _} = Entry.parse_time("2021-11-06")
  end

  test "parses time, truncating microseconds" do
    {:ok, %{microsecond: {microsecond, precision}}} = Entry.parse_time("2018-08-22T10:07:06.121Z")

    assert microsecond == 0
    assert precision == 0
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
