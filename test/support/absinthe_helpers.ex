defmodule GraphBankingWeb.AbsintheHelpers do
  @spec query_skeleton(any, any) :: %{optional(<<_::40, _::_*32>>) => binary}
  def query_skeleton(query, query_name) do
    %{
      "operationName" => "#{query_name}",
      "query" => "query #{query_name} #{query}",
      "variables" => "{}"
    }
  end

  def mutation_skeleton(query) do
    %{
      "operationName" => "",
      "query" => "#{query}",
      "variables" => ""
    }
  end
end
