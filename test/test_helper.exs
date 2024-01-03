ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(ExRss.Repo, :manual)

Mox.defmock(ExRss.TestBroadcaster, for: ExRss.UpdateBroadcaster)
Application.put_env(:ex_rss, :update_broadcaster, ExRss.TestBroadcaster)
