defmodule GraphBanking.Helper do
  @moduledoc false

  @doc """
  Converts the changeset errors to a format that Absinthe understand
  """
  @spec parse_errors(Ecto.Changeset.t()) :: [any]
  def parse_errors(%Ecto.Changeset{} = changeset) do
    Enum.map(changeset.errors, fn {key, {value, _}} ->
      %{message: "#{key} #{value}"}
    end)
  end
end
