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
  def reduce(enumerable, acc, fun), do: enumerable |> to_list |> reduce(acc, fun)

  def reduce([], _), do: raise(MyEnum.EmptyError)
  def reduce([h|t], fun), do: reduce(t, h, fun)
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
  def reduce_while(enumerable, acc, fun), do: enumerable |> to_list |> reduce_while(acc, fun)

  def to_list(l) when is_list(l), do: l
  def to_list(e..e), do: [e]
  def to_list(s..e) when s < e, do: [s| to_list(s+1..e)]
  def to_list(s..e) when s > e, do: [s| to_list(s-1..e)]
  def to_list(m) when is_map(m), do: Map.to_list(m)

  def reverse([]), do: []
  def reverse([h|t]), do: reverse(t)++[h]
  def reverse(enumerable), do: enumerable |> to_list |> reverse
  def reverse(enumerable, tail) do
    enumerable |> reverse |> concat(tail)
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
  def max(enumerable, empty_fallback \\ fn -> raise(MyEnum.EmptyError) end) do
    max_by(enumerable, fn x -> x end, empty_fallback)
  end

  def max_by(enumerable, fun, empty_fallback \\ fn -> raise(MyEnum.EmptyError) end) do
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

  def min(enumerable, empty_fallback \\ fn -> raise(MyEnum.EmptyError) end) do
    min_by(enumerable, fn x -> x end, empty_fallback)
  end

  def min_by(enumerable, fun, empty_fallback \\ fn -> raise(MyEnum.EmptyError) end) do
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

  def min_max(enumerable, empty_fallback \\ fn -> raise(MyEnum.EmptyError) end) do
    cond do
      enumerable |> empty? -> empty_fallback.()
      true ->
        min = enumerable |> MyEnum.min(empty_fallback)
        max = enumerable |> MyEnum.max(empty_fallback)
        {min, max}
    end
  end

  def min_max_by(enumerable, fun, empty_fallback \\ fn -> raise(MyEnum.EmptyError) end) do
    cond do
      enumerable |> empty? -> empty_fallback.()
      true ->
        min = enumerable |> MyEnum.min_by(fun, empty_fallback)
        max = enumerable |> MyEnum.max_by(fun, empty_fallback)
        {min, max}
    end
  end

  def filter(enumerable, fun) do
    enumerable
    |> reduce([],
      fn x, acc ->
        cond do
          fun.(x)-> [x|acc]
          true -> acc
        end
      end
    )
    |> reverse
  end

  def reject(enumerable, fun) do
    enumerable |> filter(fn x -> !(fun.(x)) end)
  end

  def empty?([]), do: true
  def empty?(%{}), do: true
  def empty?(_), do: false

  def count(enumerable), do: enumerable |> reduce(0, fn _, acc -> acc + 1 end)
  def count(enumerable, fun) do
    enumerable
    |> reduce(0,
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
    enumerable |> to_list |> all?(fun)
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
    enumerable |> to_list |> any?(fun)
  end

  def at(enumerable, index, default \\ nil)
  def at([], _, default), do: default
  def at([h|_], 0, _), do: h
  def at([_|t], index, default) when index > 0 do
    at(t, index-1, default)
  end
  def at(enumerable, index, default) when index < 0 do
    enumerable |> reverse |> at(-1*index-1, default)
  end

  def fetch!(enumerable, index) do
    elem = enumerable |> at(index)
    cond do
      elem == nil -> raise MyEnum.OutOfBoundsError
      true -> {:ok, elem}
    end
  end
  def fetch(enumerable, index) do
    elem = enumerable |> at(index)
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
    :ok
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
    enumerable |> reverse |> take(-1*amount)
  end
  def take(enumerable, amount) do
    cond do
      count(enumerable) <= amount -> enumerable |> to_list
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

  def take_every(enumerable, 0), do: []
  def take_every(enumerable, nth) do
    enumerable
    |> reduce({0, []},
         fn x, _acc={index, list} ->
           cond do
             rem(index, nth) == 0 -> {index+1, [x|list]}
             true -> {index+1, list}
           end
         end
       )
    |> (fn {_, list} -> list |> reverse end).()
  end

  def take_while(enumerable, fun) do
    enumerable
    |> reduce_while([],
         fn x, acc ->
           cond do
             fun.(x) -> {:cont, [x|acc]}
             true -> {:halt, acc}
           end
         end
       )
    |> reverse
  end

  def drop(enumerable, amount) when amount >= 0 do
    enumerable
    |> reduce({0, []},
         fn x, acc={index, list} ->
           cond do
             index >= amount -> {index+1, [x|list]}
             true -> {index+1, list}
           end
         end
       )
     |> (fn {_, list} -> list |> reverse end).()
  end
  def drop(enumerable, amount) when amount < 0 do
    drop(enumerable|> reverse, -1*amount) |> reverse
  end

  def drop_every(enumerable, 0), do: enumerable |> to_list
  def drop_every(enumerable, nth) do
    enumerable
    |> reduce({0, []},
         fn x, acc={index, list} ->
           cond do
             rem(index, nth) == 0 -> {index+1, list}
             true -> {index+1, [x|list]}
           end
         end
       )
    |> (fn {_, list} -> list |> reverse end).()
  end

  def drop_while(enumerable, fun) do
    index = find_index(enumerable, fn x -> !fun.(x) end)
    enumerable |> slice(index..-1)
  end

  def chunk_by(enumerable, fun) do
    [head|tail] = enumerable |> to_list
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
    c = enumerable |> count

    enumerable =
      cond do
        leftover == :discard -> (enumerable |> to_list) ++ [:discard]
        true -> enumerable ++ leftover
      end

    enumerable
    |> reduce_while({0, []},
         fn x, acc={index, list} ->
           cond do
             index < c -> {:cont, {index + step, [slice(enumerable, index, count)|list]}}
             true -> {:halt, acc}
           end
         end
       )
    |> (
         fn {_, list=[h|t]} ->
           cond do
             :discard in h -> t |> reverse
             true -> list |> reverse
           end
         end
       ).()
  end
  def chunk_every(enumerable, count) do
    chunk_every(enumerable, count, count)
  end

  def chunk_while(enumerable, acc, chunk_fun, after_fun) do
    enumerable
    |> reduce_while([acc],
         fn x, _acc=[h|t] ->
           case chunk_fun.(x, h) do
             {:cont, chunk, new_acc_init} -> {:cont, [new_acc_init, chunk|t]}
             {:cont, chunk} -> {:cont, [chunk|t]}
             {:halt, chunk} -> {:halt, [chunk|t]}
           end
         end
       )
    |> (fn [h|t] -> (t |> reverse) ++
                    case after_fun.(h) do
                      {:cont, _acc} -> []
                      {:cont, element, _acc}  -> element
                    end
        end).()
  end

  defp _find([], default, _fun, _index), do: {default, default, default}
  defp _find([h|t], default, fun, index) do
    value = fun.(h)
    cond do
      value -> {index, value, h}
      true -> _find(t, default, fun, index+1)
    end
  end
  defp _find(enumerable, default, fun, index) do
    enumerable |> to_list |> _find(default, fun, index)
  end

  def find(enumerable, default \\ nil, fun) do
    enumerable |> to_list |> _find(default, fun, 0)
    |> (fn {_,_,x} -> x end).()
  end

  def find_index(enumerable, default \\ nil, fun) do
    enumerable |> to_list |> _find(default, fun, 0)
    |> (fn {x,_,_} -> x end).()
  end

  def find_value(enumerable, default \\ nil, fun) do
    enumerable |> to_list |> _find(default, fun, 0)
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
    enumerable |> map(mapper) |> join(joiner)
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

  def random(enumerable) do
    c = enumerable |> count
    p = :rand.uniform(c) - 1
    enumerable|> Enum.at(p)
  end

  def slice(enumerable, s..e) do
    cond do
      s >=0 and e < 0 ->
        e = count(enumerable) + e + 1
        slice(enumerable, s, s..e)
      s < 0 and e >= 0 ->
        s = count(enumerable) + s + 1
        slice(enumerable, s, s..e)
      true -> slice(enumerable, s, (e-s)+1)
    end
  end

  def slice(enumerable, start_index, amount) when start_index >= 0 do
    enumerable
    |> reduce_while({0,[]},
         fn x, _acc={index, list} ->
           cond do
             count(list) >= amount -> {:halt, {index+1, list}}
             index >= start_index -> {:cont, {index+1, [x|list]}}
             true -> {:cont, {index+1, list}}
           end
         end
       )
    |> (fn {_, list} -> list |> reverse end).()
  end
  def slice(enumerable, start_index, amount) when start_index < 0 do
    start_index = count(enumerable) + start_index
    cond do
      start_index < 0 -> []
      true -> slice(enumerable, start_index, amount)
    end
  end

  def reverse_slice(enumerable, start_index, count) do
    {hl, tl} = enumerable |> split(start_index)
    {bl, tl} = tl |> split(count)
    hl ++ reverse(bl) ++ tl
  end

  def split(enumerable, count) when count >=0 do
    enumerable
    |> reduce_while({[],[]},
         fn x, acc={hl, tl} ->
           cond do
             count(hl) >= count -> {:halt, {hl, enumerable |> slice(x-1..-1)}}
             true -> {:cont, {[x|hl], tl}}
           end
         end
       )
    |> (fn {hl, tl} -> {hl |> reverse, tl} end).()
  end
  def split(enumerable, count) when count < 0 do
    count = count(enumerable) + count
    cond do
      count < 0 -> {[], enumerable |> to_list}
      true -> enumerable |> split(count)
    end
  end

  def split_while(enumerable, fun) do
    index = find_index(enumerable, fn x -> !fun.(x) end)
    cond do
      index == nil -> {enumerable |> to_list, []}
      true -> enumerable |> split(index)
    end
  end

  def split_with(enumerable, fun) do
    enumerable
    |> reduce({[],[]},
         fn x, acc={tl, fl} ->
           cond do
             fun.(x) -> {[x|tl],fl}
             true -> {tl, [x|fl]}
           end
         end
       )
    |> (fn {tl, fl} -> {tl |> reverse, fl |> reverse} end).()
  end

  defp _shuffle([], acc), do: acc
  defp _shuffle(list, acc) do
     e = list |> random
    _shuffle(list |> filter(fn x -> x != e end), [e|acc])
  end
  def shuffle(enumerable) do
    _shuffle(enumerable |> to_list, [])
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
