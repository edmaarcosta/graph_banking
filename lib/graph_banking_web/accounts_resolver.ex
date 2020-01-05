defmodule GraphBankingWeb.AccountsResolver do
  @moduledoc false

  alias GraphBanking.Accounts
  alias GraphBanking.Accounts.Account
  alias GraphBanking.Helper

  @doc """
  Returns all accounts from context.
  """
  @spec all_accounts(any, any, any) :: {:ok, list(Account.t())}
  def all_accounts(_root, _args, _info) do
    accounts = Accounts.list_accounts()

    {:ok, accounts}
  end

  @doc """
  Returns transactions from an account.
  """
  @spec get_transactions(%{id: any}, any, any) :: {:ok, any}
  def get_transactions(%{id: sender_id}, _args, _info) do
    transactions = Accounts.list_transactions(sender_id)

    {:ok, transactions}
  end

  @doc """
  Open an account with an initial balance
  """
  @spec open_account(%{balance: any}, any) :: {:ok, Account.t()} | {:error, any}
  def open_account(%{balance: balance}, _info) do
    case Accounts.open_account(%{current_balance: balance}) do
      # if returns an error with a changeset
      {:error, %Ecto.Changeset{} = changeset} ->
        # pass the changeset to a helper to parse the errors
        {:error, Helper.parse_errors(changeset)}

      other ->
        other
    end
  end

  @doc """
  Transfers money to an account.
  """
  @spec transfer_money(%{sender: any, address: any, amount: any}, any) :: any
  def transfer_money(%{sender: sender_id, address: address_id, amount: amount}, _info) do
    %{
      sender_id: sender_id,
      address_id: address_id,
      amount: amount,
      # sets when the operation occurred
      when: DateTime.utc_now()
    }
    |> Accounts.transfer_money()
    |> case do
      # if returns an error with a changeset
      {:error, %Ecto.Changeset{} = changeset} ->
        # pass the changeset to a helper to parse the errors
        {:error, Helper.parse_errors(changeset)}

      other ->
        other
    end
  end
end
