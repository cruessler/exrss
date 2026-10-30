ExUnit.start()

# Set up the Mix shell to send messages to the current process so that we can
# run assertions such as `assert_receive {:mix_shell, …}`.
Mix.shell(Mix.Shell.Process)

Ecto.Adapters.SQL.Sandbox.mode(ExRss.Repo, :manual)

Mox.defmock(ExRss.TestBroadcaster, for: ExRss.UpdateBroadcaster)
Application.put_env(:ex_rss, :update_broadcaster, ExRss.TestBroadcaster)
