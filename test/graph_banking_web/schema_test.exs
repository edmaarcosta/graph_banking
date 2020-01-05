defmodule GraphBanking.SchemaTest do
  use GraphBankingWeb.ConnCase
  alias GraphBankingWeb.AbsintheHelpers
  alias GraphBanking.Accounts

  @account_a %{current_balance: Decimal.cast(100)}
  @account_b %{current_balance: Decimal.cast(156.30)}
  @api_endpoint "/api"

  describe "Account operations" do
    test "open an account", context do
      mutation = """
      mutation {
        openAccount(balance: #{@account_a.current_balance}) {
          currentBalance
        }
      }
      """

      res = post(context.conn, @api_endpoint, AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["data"]["openAccount"]["currentBalance"] ==
               to_string(@account_a.current_balance)
    end

    test "don't allow negative balance", context do
      mutation = """
      mutation {
        openAccount(balance: -500) {
          uuid
          currentBalance
        }
      }
      """

      res = post(context.conn, @api_endpoint, AbsintheHelpers.mutation_skeleton(mutation))

      assert res.status == 200
      assert String.contains?(res.resp_body, "balance can't be less than 0")
    end

    test "allow balance 0", context do
      mutation = """
      mutation {
        openAccount(balance: 0) {
          uuid
          currentBalance
        }
      }
      """

      res = post(context.conn, @api_endpoint, AbsintheHelpers.mutation_skeleton(mutation))

      assert json_response(res, 200)["data"]["openAccount"]["currentBalance"] == "0"
    end

    test "query empty accounts", context do
      query = """
      {
        account {
          uuid
          currentBalance
          transactions {
            uuid
            address
            amount
            when
          }
        }
      }
      """

      res = post(context.conn, @api_endpoint, AbsintheHelpers.query_skeleton(query, "account"))

      assert json_response(res, 200)["data"]["account"] == []
    end

    test "query account without transactions", context do
      {:ok, account} = Accounts.open_account(@account_a)

      query = """
      {
        account {
          uuid
          currentBalance
          transactions {
            uuid
            address
            amount
            when
          }
        }
      }
      """

      res = post(context.conn, @api_endpoint, AbsintheHelpers.query_skeleton(query, "account"))

      assert json_response(res, 200)["data"]["account"] ==
               [
                 %{
                   "uuid" => "#{account.id}",
                   "currentBalance" => "100",
                   "transactions" => []
                 }
               ]
    end

    test "query account with transactions", context do
      {:ok, account_a} = Accounts.open_account(@account_a)
      {:ok, account_b} = Accounts.open_account(@account_b)

      {:ok, transaction} =
        Accounts.transfer_money(%{
          sender_id: account_a.id,
          address_id: account_b.id,
          amount: 30,
          when: ~N[2020-01-01 18:00:00]
        })

      query = """
      {
        account {
          uuid
          currentBalance
          transactions {
            uuid
            address
            amount
            when
          }
        }
      }
      """

      res = post(context.conn, @api_endpoint, AbsintheHelpers.query_skeleton(query, "account"))

      assert json_response(res, 200)["data"]["account"] ==
               [
                 %{
                   "uuid" => "#{account_a.id}",
                   "currentBalance" => "70",
                   "transactions" => [
                     %{
                       "uuid" => transaction.id,
                       "amount" => "30",
                       "address" => account_b.id,
                       "when" => "2020-01-01T18:00:00"
                     }
                   ]
                 },
                 %{
                   "uuid" => "#{account_b.id}",
                   "currentBalance" => "186.3",
                   "transactions" => []
                 }
               ]
    end
  end

  describe "Transfer operations" do
    test "transfer money", context do
      {:ok, account_a} = Accounts.open_account(@account_a)
      {:ok, account_b} = Accounts.open_account(@account_b)

      mutation = """
      mutation {
        transferMoney(sender: "#{account_a.id}", address: "#{account_b.id}", amount: 43.70) {
          address
          amount
        }
      }
      """

      res = post(context.conn, @api_endpoint, AbsintheHelpers.mutation_skeleton(mutation))

      # extract the new balance from accounts
      %{current_balance: account_balance_a} = Accounts.get_account!(account_a.id)
      %{current_balance: account_balance_b} = Accounts.get_account!(account_b.id)

      assert json_response(res, 200)["data"]["transferMoney"]["address"] ==
               to_string(account_b.id)

      assert json_response(res, 200)["data"]["transferMoney"]["amount"] == to_string("43.7")
      assert Decimal.equal?(account_balance_a, Decimal.cast(56.30))
      assert Decimal.equal?(account_balance_b, Decimal.cast(200))
    end

    test "insufficient balance", context do
      {:ok, account_a} = Accounts.open_account(@account_a)

      mutation = """
      mutation {
        transferMoney(sender: "#{account_a.id}", address: "unnecessary_id", amount: 500) {
          address
          amount
        }
      }
      """

      res = post(context.conn, @api_endpoint, AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] == "insufficient balance"
    end

    test "amount equals zero", context do
      {:ok, account_a} = Accounts.open_account(@account_a)

      mutation = """
      mutation {
        transferMoney(sender: "#{account_a.id}", address: "unnecessary_id", amount: 0) {
          address
          amount
        }
      }
      """

      res = post(context.conn, @api_endpoint, AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] == "amount must be greater than 0"
    end

    test "not enough params", context do
      {:ok, account_a} = Accounts.open_account(@account_a)

      mutation = """
      mutation {
        transferMoney(sender: "#{account_a.id}") {
          address
          amount
        }
      }
      """

      res = post(context.conn, @api_endpoint, AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "In argument \"amount\": Expected type \"Decimal!\", found null."
    end

    test "transfer money to sender account", context do
      {:ok, account_a} = Accounts.open_account(@account_a)

      mutation = """
      mutation {
        transferMoney(sender: "#{account_a.id}", address: "#{account_a.id}", amount: 20) {
          address
          amount
        }
      }
      """

      res = post(context.conn, @api_endpoint, AbsintheHelpers.mutation_skeleton(mutation))

      assert hd(json_response(res, 200)["errors"])["message"] ==
               "cannot transfer money to sender account"
    end
  end
end
