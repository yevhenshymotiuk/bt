defmodule Bt.Map do
  @spec swap(map) :: map
  def swap(map) do
    map
    |> Enum.map(fn {k, v} -> {v, k} end)
    |> Enum.into(%{})
  end
end
