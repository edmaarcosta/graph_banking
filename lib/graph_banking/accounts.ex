defmodule GraphBanking.Accounts do
  @moduledoc """
  The Accounts context for centralize all operations
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias GraphBanking.Repo
  alias GraphBanking.Accounts.{Account, Transaction}

  @doc """
  Returns the list of accounts.

  ## Examples

      iex> list_accounts()
      [%Account{}, ...]

  """
  @spec list_accounts() :: list(Account.t())
  def list_accounts, do: Repo.all(Account)

  @doc """
  Get a singles account by id.

  Raises `Ecto.NoResultsError` if the Account does not exist.

  ## Exemples

      iex> get_account!("565-65-98")
      %Account{}

      iex> get_account!("1")
      ** (Ecto.NoResultsError)

  """
  @spec get_account!(any) :: Account.t() | Ecto.NoResultsError.t()
  def get_account!(id), do: Repo.get!(Account, id)

  @doc """
  Open an account with balance. Allow open only if balance is positive.

  ## Examples

      iex> create_account(%{current_balance: 50})
      {:ok, %Account{}}

      iex> create_account(%{current_balance: -50})
      {:error, "error message"}

  """
  @spec open_account(any) :: {:ok, Account.t()} | {:error, any}
  def open_account(%{current_balance: balance} = attrs) do
    if Decimal.negative?(balance) do
      {:error, "balance can't be less than 0"}
    else
      %Account{}
      |> Account.changeset(attrs)
      |> Repo.insert()
    end
  end

  @doc """
  Returns a list of transactions from a sender.

  ## Examples

      iex> list_transactions("556-654-654)
      [%Transaction{}, ...]

  """
  @spec list_transactions(any) :: list(Transaction.t())
  def list_transactions(sender_id) do
    Transaction
    |> where([t], t.sender_id == ^sender_id)
    |> Repo.all()
  end

  @doc """
  Transfers money from a account to another.
  Checks if the sender account has enough balance and others validations.

  ## Attributes

  `%{ sender_id: sender, address_id: address, amount: amount }`

  ## Examples

      iex> transfer_money(attrs)
      {:ok, %Transaction{}}

      iex> transfer_money(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec transfer_money(any) :: {:ok, Transaction.t()} | {:error, any()}
  def transfer_money(attrs) do
    # do some validations to check if attributes are ok
    case transfer_validations(attrs) do
      :ok ->
        # use multi to keeps all operations with database in one transaction and allow a consistent rollback
        Multi.new()
        |> Multi.insert(:transaction, create_transaction_changeset(attrs))
        |> Multi.update(
          :sub_account,
          change_current_balance_changeset(attrs[:sender_id], :sub, attrs[:amount])
        )
        |> Multi.update(
          :add_account,
          change_current_balance_changeset(attrs[:address_id], :add, attrs[:amount])
        )
        |> Repo.transaction()
        |> case do
          {:ok, %{transaction: transaction}} ->
            {:ok, transaction}

          {:error, _, %Ecto.Changeset{} = changeset, _} ->
            {:error, changeset}
        end

      error ->
        error
    end
  end

  # Checks if the transfer attributes are valid
  @spec transfer_validations(any) :: :ok | {:error, String.t()}
  def transfer_validations(%{sender_id: sender, address_id: address, amount: amount}) do
    %{current_balance: balance} = get_account!(sender)

    cond do
      # it's not allow transfer to the same account
      sender == address ->
        {:error, "cannot transfer money to sender account"}

      # current balance from sender it's not enough to transfers
      Decimal.lt?(balance, amount) ->
        {:error, "insufficient balance"}

      # it's not allow transfer an amount less than zero
      Decimal.equal?(amount, Decimal.cast(0)) or Decimal.lt?(amount, Decimal.cast(0)) ->
        {:error, "amount must be greater than 0"}

      # if no inconsistency, returns :ok
      true ->
        :ok
    end
  end

  # Creates a changeset with transaction attributes to use in Ecto.Multi
  @spec create_transaction_changeset(any) :: Ecto.Changeset.t()
  defp create_transaction_changeset(attrs) do
    %Transaction{}
    |> Transaction.changeset(attrs)
  end

  # Updates the balance (sum) of an account and return a changeset to use in Ecto.Multi
  @spec change_current_balance_changeset(any, atom(), any) :: Ecto.Changeset.t()
  defp change_current_balance_changeset(account_id, :add, amount) do
    account = get_account!(account_id)
    updated_balance = Decimal.add(account.current_balance, amount)

    account
    |> Account.changeset(%{current_balance: updated_balance})
  end

  # Updates the balance (subtract) of an account and return a changeset to use in Ecto.Multi
  defp change_current_balance_changeset(account_id, :sub, amount) do
    account = get_account!(account_id)
    updated_balance = Decimal.sub(account.current_balance, amount)

    account
    |> Account.changeset(%{current_balance: updated_balance})
  end
end
