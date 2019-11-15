defmodule MyEnum.EmptyError do
  defexception []
  def message(_), do: "empty error"
end