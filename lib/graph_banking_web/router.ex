defmodule GraphBankingWeb.Router do
  use GraphBankingWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/" do
    pipe_through :api

    forward "/api", Absinthe.Plug.GraphiQL,
      schema: GraphBankingWeb.Schema,
      interface: :simple,
      context: %{pubsub: GraphBankingWeb.Endpoint}
  end
end
