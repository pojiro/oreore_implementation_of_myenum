defmodule MyEnum.OutOfBoundsError do
  defexception []
  def message(_), do: "out of bounds error"
end