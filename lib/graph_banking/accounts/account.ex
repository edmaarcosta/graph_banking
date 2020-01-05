defmodule GraphBanking.Accounts.Account do
  use Ecto.Schema
  import Ecto.Changeset
  alias GraphBanking.Accounts.Transaction

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "accounts" do
    field :current_balance, :decimal
    has_many :transactions, Transaction, foreign_key: :sender_id

    timestamps()
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:current_balance])
    |> validate_required([:current_balance])
  end
end
