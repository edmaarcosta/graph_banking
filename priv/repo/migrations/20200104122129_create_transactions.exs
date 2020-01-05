defmodule GraphBanking.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :amount, :decimal
      add :when, :naive_datetime
      add :sender_id, references(:accounts, on_delete: :nothing, type: :binary_id)
      add :address_id, references(:accounts, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:transactions, [:sender_id])
    create index(:transactions, [:address_id])
  end
end
