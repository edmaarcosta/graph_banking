defmodule GraphBanking.Accounts.Transaction do
  use Ecto.Schema
  import Ecto.Changeset
  alias GraphBanking.Accounts.Account

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "transactions" do
    field :amount, :decimal
    field :when, :naive_datetime
    belongs_to :sender, Account
    belongs_to :address, Account

    timestamps()
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:amount, :when, :sender_id, :address_id])
    |> validate_required([:amount, :when, :sender_id, :address_id])
  end
end
