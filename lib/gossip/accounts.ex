defmodule Gossip.Accounts do
  @moduledoc """
  Context for accounts
  """

  import Ecto.Query
  require Logger

  alias Gossip.Accounts.User
  alias Gossip.Emails
  alias Gossip.Games.Game
  alias Gossip.Mailer
  alias Gossip.Repo

  @type user_params :: map()
  @type token :: String.t()

  @doc """
  Start a new user
  """
  @spec new() :: Ecto.Changeset.t()
  def new(), do: %User{} |> User.changeset(%{})

  @doc """
  Register a new user
  """
  @spec register(user_params()) :: {:ok, User.t()}
  def register(params) do
    %User{}
    |> User.changeset(params)
    |> Repo.insert()
  end

  @doc """
  Find a user by the token
  """
  @spec from_token(token()) :: {:ok, User.t()} | {:error, :not_found}
  def from_token(token) do
    case Repo.get_by(User, token: token) do
      nil ->
        {:error, :not_found}

      user ->
        {:ok, preload(user)}
    end
  end

  defp preload(user) do
    Repo.preload(user, games: from(g in Game, order_by: [g.id]))
  end

  @doc """
  Validate a login
  """
  @spec validate_login(String.t(), String.t()) :: {:ok, User.t()} | {:error, :invalid}
  def validate_login(email, password) do
    case Repo.get_by(User, email: email) do
      nil ->
        Comeonin.Bcrypt.dummy_checkpw()
        {:error, :invalid}

      user ->
        check_password(user, password)
    end
  end

  defp check_password(user, password) do
    case Comeonin.Bcrypt.checkpw(password, user.password_hash) do
      true ->
        {:ok, user}

      false ->
        {:error, :invalid}
    end
  end

  @doc """
  Start password reset
  """
  @spec start_password_reset(String.t()) :: :ok
  def start_password_reset(email) do
    query = User |> where([u], u.email == ^email)

    case query |> Repo.one() do
      nil ->
        Logger.warn("Password reset attempted for #{email}")

        :ok

      user ->
        Logger.info("Starting password reset for #{user.email}")

        user
        |> User.password_reset_changeset()
        |> Repo.update!()
        |> Emails.password_reset()
        |> Mailer.deliver_now()

        :ok
    end
  end

  @doc """
  Reset a password
  """
  @spec reset_password(String.t(), map()) :: {:ok, User.t()} | :error
  def reset_password(token, params) do
    with {:ok, uuid} <- Ecto.UUID.cast(token),
         {:ok, user} <- find_user_by_reset_token(uuid),
         {:ok, user} <- check_password_reset_expired(user) do
      user
      |> User.password_changeset(params)
      |> Repo.update()
    end
  end

  defp find_user_by_reset_token(uuid) do
    query = User |> where([u], u.password_reset_token == ^uuid)

    case query |> Repo.one() do
      nil ->
        :error

      user ->
        {:ok, user}
    end
  end

  defp check_password_reset_expired(user) do
    case Timex.after?(Timex.now(), user.password_reset_expires_at) do
      true ->
        :error

      false ->
        {:ok, user}
    end
  end
end
