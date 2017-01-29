defmodule ExRss.Session do
  alias ExRss.Repo
  alias ExRss.User.Account

  def login(params) do
    user = Repo.get_by(Account, email: String.downcase(params["email"]))

    case authenticate(user, params["password"]) do
      true -> {:ok, user}
      _    -> :error
    end
  end

  defp authenticate(user, password) do
    case user do
      nil -> false
      _   -> Comeonin.Bcrypt.checkpw(password, user.hashed_password)
    end
  end
end
