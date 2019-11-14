defmodule MyEnum do
  @moduledoc """
  Documentation for MyEnum.
  """

  @doc """
  Hello world.

  ## Examples

      iex> MyEnum.hello()
      :world

  """
  def hello do
    :world
  end

  def reduce([], acc , _), do: acc
  def reduce([h|t], acc, fun), do: reduce(t, fun.(h, acc), fun)
  # def reduce(s..e, acc, fun), do: reduce(to_list(s..e), acc, fun)
  # def reduce(enumerable, acc, fun) when is_map(enumerable), do: reduce(Map.to_list(enumerable), acc, fun)
  def reduce(enumerable, acc, fun), do: enumerable |> to_list |> reduce(acc, fun)

  def reduce([h|t], fun), do: reduce(t, h, fun)
  # def reduce(s..e, fun), do: reduce(to_list(s..e), fun)
  # def reduce(enumerable, fun) when is_map(enumerable), do: reduce(Map.to_list(enumerable), fun)
  def reduce(enumerable, fun), do: enumerable |> to_list |> reduce(fun)

  def reduce_while([], acc, _), do: acc
  def reduce_while([h|t], acc, fun) do
    {flag, value} = fun.(h, acc)
    cond do
      flag == :cont -> reduce_while(t, value, fun)
      flag == :halt -> value
      true -> reduce_while(t, value, fun)
    end
  end
  def reduce_while(s..e, acc, fun), do: reduce_while(to_list(s..e), acc, fun)

  def to_list(l) when is_list(l), do: l
  def to_list(m) when is_map(m), do: Map.to_list(m)
  def to_list(e..e), do: [e]
  def to_list(s..e) when s < e, do: [s| to_list(s+1..e)]
  def to_list(s..e) when s > e, do: [s| to_list(s-1..e)]

  def reverse([]), do: []
  def reverse([h|t]), do: reverse(t)++[h]
  def reverse(s..e), do: to_list(e..s)
  def reverse(enumerable, tail) do
    enumerable
    |> reverse
    |> concat(tail)
  end

  def map(enumerable, fun) do
    enumerable
    |> reduce([], fn x, acc -> [fun.(x) | acc] end)
    |> Enum.reverse
  end

  def map_reduce(enumerable, acc, fun) do
    enumerable
    |> reduce({[], acc},
         fn x, {list, acc1} ->
           tuple = fun.(x, acc1)
           {[elem(tuple, 0)|list], elem(tuple, 1)}
         end
       )
    |> (fn {m, r} -> {m |> reverse, r} end).()
  end

  def map_every(enumerable, 0, _), do: enumerable |> to_list
  def map_every(enumerable, nth, fun) when nth > 0 do
    enumerable
    |> reduce({0, []},
         fn x, acc={index, list} ->
           cond do
             rem(index, nth) == 0 -> {index+1, [fun.(x)|list]}
             true -> {index+1, [x|list]}
           end
         end
       )
    |> (fn {_, list} -> list |> reverse end).()
  end

  def sum(enumerable), do: reduce(enumerable, 0, &(&1+&2))


  # リファクタリングのいい例を示せる
  #def max(enumerable, empty_fallback \\ fn -> raise(Enum.EmptyError) end)
  #def max([], empty_fallback), do: empty_fallback.()
  #def max(enumerable, _) do
  #  enumerable
  #  |> reduce(
  #       fn
  #         x, acc when x > acc -> x
  #         _, acc -> acc
  #       end
  #     )
  #end
  def max(enumerable, empty_fallback \\ fn -> raise(Enum.EmptyError) end) do
    max_by(enumerable, fn x -> x end, empty_fallback)
  end

  def max_by(enumerable, fun, empty_fallback \\ fn -> raise(Enum.EmptyError) end) do
    cond do
      enumerable |> empty? -> empty_fallback.()
      true ->
        enumerable
        |> reduce(
             fn x, acc ->
               cond do
                 fun.(x) > fun.(acc) -> x
                 true -> acc
               end
             end
           )
    end
  end

  def min(enumerable, empty_fallback \\ fn -> raise(Enum.EmptyError) end) do
    min_by(enumerable, fn x -> x end, empty_fallback)
  end

  def min_by(enumerable, fun, empty_fallback \\ fn -> raise(Enum.EmptyError) end) do
    cond do
      enumerable |> empty? -> empty_fallback.()
      true ->
        enumerable
        |> reduce(
             fn x, acc ->
               cond do
                 fun.(x) < fun.(acc) -> x
                 true -> acc
               end
             end
           )
    end
  end

  def min_max(enumerable, empty_fallback \\ fn -> raise(Enum.EmptyError) end) do
    cond do
      enumerable |> empty? -> empty_fallback.()
      true ->
        min = enumerable |> MyEnum.min(empty_fallback)
        max = enumerable |> MyEnum.max(empty_fallback)
        {min, max}
    end
  end

  def filter(enumerable, fun) do
    reduce(enumerable, [],
      fn x, acc ->
        cond do
          fun.(x)-> [x|acc]
          true -> acc
        end
      end
    )
    |> Enum.reverse
  end

  def reject(enumerable, fun) do
    filter(enumerable, fn x -> !(fun.(x)) end)
  end

  def empty?([]), do: true
  def empty?(%{}), do: true
  def empty?(_), do: false

  def count(enumerable), do: reduce(enumerable, 0, fn _, acc -> acc + 1 end)
  def count(enumerable, fun) do
    reduce(enumerable, 0,
      fn x, acc ->
        cond do
          fun.(x) -> acc + 1
          true -> acc
        end
      end
    )
  end

  def all?(enumerable, fun \\ fn x -> x end)
  def all?([], _), do: true
  def all?([h|t], fun) do
    cond do
      fun.(h) -> all?(t, fun)
      true -> false
    end
  end
  def all?(enumerable, fun) do
    all?(to_list(enumerable), fun)
  end

  def any?(enumerable, fun \\ fn x -> x end)
  def any?([], _), do: false
  def any?([h|t], fun) do
    cond do
      fun.(h) -> true
      true -> any?(t, fun)
    end
  end
  def any?(enumerable, fun) do
    any?(to_list(enumerable), fun)
  end

  def at(enumerable, index, default \\ nil)
  def at([], _, default), do: default
  def at([h|_], 0, _), do: h
  def at([_|t], index, default) when index > 0 do
    at(t, index-1, default)
  end
  def at(enumerable, index, default) when index < 0 do
    at(reverse(enumerable), -1*index-1, default)
  end

  def fetch!(enumerable, index) do
    elem = at(enumerable, index)
    cond do
      elem == nil -> raise Enum.OutOfBoundsError
      true -> {:ok, elem}
    end
  end
  def fetch(enumerable, index) do
    elem = at(enumerable, index)
    cond do
      elem == nil -> :error
      true -> {:ok, elem}
    end
  end

  def concat(enumerable) do
    enumerable
    |> reduce([], fn x, acc -> acc ++ to_list(x) end)
  end
  def concat(left, right), do: to_list(left) ++ to_list(right)

  def with_index(enumerable, offset \\ 0) do
    enumerable
    |> reduce({offset, []},
         fn x, {index, list} ->
           {index+1, [{x, index}|list]}
         end
       )
    |> (fn {_, list} -> reverse(list) end).()
  end

  def each(enumerable, fun) do
    enumerable |> reduce(nil, fn x, _ -> fun.(x) end)
  end

  def uniq(enumerable) do
    enumerable
    |> reduce([],
         fn x, acc ->
           cond do
             x not in acc -> [x|acc]
             true -> acc
           end
         end
       )
    |> reverse
  end

  def uniq_by(enumerable, fun) do
    enumerable
    |> reduce({[],[]},
         fn x, acc={acc1, acc2} ->
           cond do
             (elem=fun.(x)) not in acc1 -> {[elem|acc1], [x|acc2]}
             true -> acc
           end
         end
       )
    |> (fn {_, acc2} -> reverse(acc2) end).()
  end

  def dedup(enumerable) do
    [head|tail] = enumerable |> to_list
    tail
    |> reduce([head],
         fn x, acc=[h|_] ->
           cond do
             x === h -> acc
             true -> [x|acc]
           end
         end
       )
    |> reverse
  end

  def dedup_by(enumerable, fun) do
    [head|tail] = enumerable |> to_list
    tail
    |> reduce([head],
         fn x, acc=[h|_] ->
           cond do
             fun.(x) === fun.(h) -> acc
             true -> [x|acc]
           end
         end
       )
    |> reverse
  end

  def take(enumerable, amount) when amount < 0 do
    take(reverse(enumerable), -1*amount)
  end
  def take(enumerable, amount) do
    cond do
      count(enumerable) <= amount -> to_list(enumerable)
      true -> enumerable
              |> reduce({amount, []},
                   fn x, acc={acc1, acc2} ->
                     cond do
                       acc1 > 0 -> {acc1-1, [x|acc2]}
                       true -> acc
                     end
                   end
                 )
              |> (fn {_, list} -> reverse(list) end).()
    end
  end

  def chunk_by(enumerable, fun) do
    [head|tail] = enumerable
    tail
    |> reduce([[head]],
         fn x, acc=[head1=[h|_]|t] ->
           cond do
             fun.(x) == fun.(h) -> [[x|head1]|t]
             true -> [[x]|acc]
           end
         end
       )
    |> map(fn x -> reverse(x) end)
    |> reverse
  end

  def chunk_every(enumerable, count, step, leftover \\ []) do
    [head|tail] = enumerable |> to_list
    tail
    |> reduce([[head]],
         fn x, acc=[h|t] ->
           cond do
             count(h) < count -> [[x|h]|t]
             true -> [[x]|acc]
           end
         end
       )
    |> map(fn x -> reverse(x) end)
    |> reverse
  end
  def chunk_every(enumerable, count) do
    chunk_every(enumerable, count, count)
  end

  defp find_impl([], default, _fun, _index), do: {default, default, default}
  defp find_impl([h|t], default, fun, index) do
    value = fun.(h)
    cond do
      value -> {index, value, h}
      true -> find_impl(t, default, fun, index+1)
    end
  end
  defp find_impl(enumerable, default, fun, index) do
    find_impl(to_list(enumerable), default, fun, index)
  end

  def find(enumerable, default \\ nil, fun) do
    find_impl(to_list(enumerable), default, fun, 0)
    |> (fn {_,_,x} -> x end).()
  end

  def find_index(enumerable, default \\ nil, fun) do
    find_impl(to_list(enumerable), default, fun, 0)
    |> (fn {x,_,_} -> x end).()
  end

  def find_value(enumerable, default \\ nil, fun) do
    find_impl(to_list(enumerable), default, fun, 0)
    |> (fn {_,x,_} -> x end).()
  end

  def scan(enumerable, fun), do: scan(enumerable, 0, fun)
  def scan(enumerable, acc, fun) do
    [head|tail] = enumerable |> to_list
    tail
    |> reduce([fun.(head, acc)],
         fn x, acc1=[h|_] ->
           [fun.(x,h)|acc1]
         end
       )
    |> reverse
  end

  def group_by(enumerable, key_fun, value_fun \\ fn x -> x end) do
    enumerable
    |> reduce(%{},
         fn x, acc ->
           Map.update(acc, key_fun.(x), [value_fun.(x)], &(&1 ++ [value_fun.(x)]))
         end
       )
  end

  def flat_map(enumerable, fun) do
    enumerable
    |> reduce([], fn x, acc -> acc ++ to_list(fun.(x)) end)
  end

  defp _flat_map_reduce([], acc, _, acc_list), do: {acc_list, acc}
  defp _flat_map_reduce(enumerable, acc, fun, acc_list) do
    [head|tail] = enumerable |> to_list
    {value, acc1} = fun.(head, acc)
    cond do
      value == :halt -> {acc_list, acc}
      true -> _flat_map_reduce(tail, acc1, fun, acc_list ++ value)
    end
  end
  def flat_map_reduce(enumerable, acc, fun) do
    _flat_map_reduce(enumerable, acc, fun, [])
  end

  def join(enumerable, joiner \\ "") do
    [head|tail] = enumerable |> to_list
    tail
    |> reduce(to_string(head), fn x, acc -> to_string(x) <> joiner <> acc end)
    |> String.reverse
  end

  def map_join(enumerable, joiner \\ "", mapper) do
    enumerable
    |> map(mapper)
    |> join(joiner)
  end

  def intersperse([], _), do: []
  def intersperse(enumerable, element) do
    [head|tail] = enumerable |> to_list
    tail
    |> reduce([head], fn x, acc ->  [x,element|acc] end)
    |> reverse
  end

  def into(enumerable, collectable) do
    into(enumerable, collectable, fn x -> x end)
  end

  def into(enumerable, collectable, transform) do
    enumerable
    |> reduce(collectable,
         fn
           x={_,_}, acc ->
             {k,v} = transform.(x)
             Map.put(acc, k, v)
           x, acc -> acc ++ [transform.(x)]
         end
       )
  end

  def member?(enumerable, element) do
    element in (enumerable |> to_list)
  end

  # def zip(enumerable) do
  #   enumerable
  #   |> reduce([],
  #        fn list, acc ->
  #          list |> reduce({}, fn x, acc -> Tuple.append(acc, x) end)
  #        end
  #      )
  # end
end
