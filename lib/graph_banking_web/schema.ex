defmodule GraphBankingWeb.Schema do
  use Absinthe.Schema

  import_types(Absinthe.Type.Custom)

  alias GraphBankingWeb.AccountsResolver, as: Resolver

  @desc "An account"
  object :account do
    field :id, non_null(:id), name: "uuid"
    field :current_balance, non_null(:decimal)

    field :transactions, list_of(:transaction) do
      # resolve transaction only if client asked
      resolve(&Resolver.get_transactions/3)
    end
  end

  @desc "A transaction"
  object :transaction do
    field :id, non_null(:id), name: "uuid"
    field :address_id, non_null(:id), name: "address"
    field :amount, :decimal
    field :when, :naive_datetime
  end

  query do
    # defines the account query
    @desc "Get accounts"
    field :account, list_of(:account) do
      resolve(&Resolver.all_accounts/3)
    end
  end

  mutation do
    # defines the opening account mutation
    @desc "Open an account"
    field :open_account, :account do
      arg(:balance, non_null(:decimal))

      resolve(&Resolver.open_account/2)
    end

    # defines the transferring mutation
    @desc "Send money to an account"
    field :transfer_money, :transaction do
      arg(:sender, non_null(:id))
      arg(:address, non_null(:id))
      arg(:amount, non_null(:decimal))

      resolve(&Resolver.transfer_money/2)
    end
  end
end
