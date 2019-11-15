defmodule MyEnumTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  doctest MyEnum

  test "greets the world" do
    assert MyEnum.hello() == :world
  end

  test "reduce/3" do
    assert MyEnum.reduce([1,2,3], 0, &(&1+&2)) == 6
  end

  test "reduce/2" do
    assert MyEnum.reduce([1,2,3], &(&1+&2)) == 6
  end

  test "reduce_while" do
    assert MyEnum.reduce_while(1..100, 0, fn x, acc ->
             if x < 5, do: {:cont, acc + x}, else: {:halt, acc}
           end) == 10
    assert MyEnum.reduce_while(1..100, 0, fn x, acc ->
             if x > 0, do: {:cont, acc + x}, else: {:halt, acc}
           end) == 5050
  end

  test "to_list/1" do
    assert MyEnum.to_list(1..5) == [1,2,3,4,5]
    assert MyEnum.to_list(5..1) == [5,4,3,2,1]
    assert MyEnum.to_list(5..5) == [5]
    assert MyEnum.to_list([]) == []
    assert MyEnum.to_list(%{}) == []
  end

  test "reverse/1" do
    assert MyEnum.reverse([1,2,3]) == [3,2,1]
    assert MyEnum.reverse([]) == []
    assert MyEnum.reverse(1..5) == [5,4,3,2,1]
  end
  test "reverse/2" do
    assert MyEnum.reverse([1,2,3],[4,5,6]) == [3,2,1,4,5,6]
  end

  test "sum" do
    assert MyEnum.sum([1,2,3]) == 6
  end

  test "map" do
    assert MyEnum.map([1,2,3], &(&1*2)) == [2,4,6]
  end

  test "map_reduce" do
    assert MyEnum.map_reduce([1, 2, 3], 0, fn x, acc -> {x * 2, x + acc} end) == {[2, 4, 6], 6}
  end

  test "map_every" do
    assert MyEnum.map_every(1..10, 2, fn x -> x + 1000 end) == [1001, 2, 1003, 4, 1005, 6, 1007, 8, 1009, 10]
    assert MyEnum.map_every(1..10, 3, fn x -> x + 1000 end) == [1001, 2, 3, 1004, 5, 6, 1007, 8, 9, 1010]
    assert MyEnum.map_every(1..5, 0, fn x -> x + 1000 end) == [1, 2, 3, 4, 5]
    assert MyEnum.map_every([1, 2, 3], 1, fn x -> x + 1000 end) ==[1001, 1002, 1003]
  end

  test "max" do
    assert MyEnum.max([1,5,10,9,4,0]) == 10
    assert_raise(Enum.EmptyError, fn -> MyEnum.max([]) end)
    assert MyEnum.max([], fn -> 0 end) == 0
  end

  test "max_by" do
    assert MyEnum.max_by(["a", "aa", "aaa"], fn x -> String.length(x) end) == "aaa"
    assert MyEnum.max_by(["a", "aa", "aaa", "b", "bbb"], &String.length/1) == "aaa"
    assert MyEnum.max_by([], &String.length/1, fn -> nil end) == nil
  end

  test "min" do
    assert MyEnum.min([1,5,10,9,4,0]) == 0
    assert_raise(Enum.EmptyError, fn -> MyEnum.min([]) end)
    assert MyEnum.min([], fn -> 0 end) == 0
  end

  test "min_by" do
    assert MyEnum.min_by(["a", "aa", "aaa"], fn x -> String.length(x) end) == "a"
    assert MyEnum.min_by(["a", "aa", "aaa", "b", "bbb"], &String.length/1) == "a"
    assert MyEnum.min_by([], &String.length/1, fn -> nil end) == nil
  end

  test "min_max" do
    assert MyEnum.min_max([2, 3, 1]) == {1, 3}
    assert MyEnum.min_max([], fn -> {nil, nil} end) == {nil, nil}
  end

  test "min_max_by" do
    assert MyEnum.min_max_by(["aaa", "bb", "c"], fn x -> String.length(x) end) == {"c", "aaa"}
    assert MyEnum.min_max_by(["aaa", "a", "bb", "c", "ccc"], &String.length/1) == {"a", "aaa"}
    assert MyEnum.min_max_by([], &String.length/1, fn -> {nil, nil} end) == {nil, nil}
  end

  test "filter" do
    assert MyEnum.filter(1..10, fn x -> rem(x, 2) == 0 end) == [2,4,6,8,10]
  end

  test "reject" do
    assert MyEnum.reject([1,2,3], fn x -> rem(x, 2) == 0 end) == [1, 3]
  end

  test "empty?" do
    assert MyEnum.empty?([]) == true
    assert MyEnum.empty?(%{}) == true
    assert MyEnum.empty?([1]) == false
  end

  test "count/1" do
    assert MyEnum.count([1,2,3]) == 3
  end

  test "count/2" do
    assert MyEnum.count([1,2,3], fn x -> rem(x, 2) == 0 end) == 1
    assert MyEnum.count([1,2,3], fn x -> rem(x, 2) != 0 end) == 2
  end

  test "all?" do
    assert MyEnum.all?([2,4,6], fn x -> rem(x, 2) == 0 end) == true
    assert MyEnum.all?([2,3,4], fn x -> rem(x, 2) == 0 end) == false
    assert MyEnum.all?([], fn x -> x > 0 end) == true
    assert MyEnum.all?([1,2,3]) == true
    assert MyEnum.all?([]) == true
    assert MyEnum.all?([1, nil, 3]) == false
    assert MyEnum.all?(1..10) == true
  end

  test "any?" do
    assert MyEnum.any?([2,4,6], fn x -> rem(x, 2) == 1 end) == false
    assert MyEnum.any?([2,3,6], fn x -> rem(x, 2) == 1 end) == true
    assert MyEnum.any?([], fn x -> x > 0 end) == false
    assert MyEnum.any?([false, false, false]) == false
    assert MyEnum.any?([false, true, false]) == true
    assert MyEnum.any?([]) == false
  end

  test "at/2" do
    assert MyEnum.at([2,4,6], 0) == 2
    assert MyEnum.at([2,4,6], 2) == 6
    assert MyEnum.at([2,4,6], 4) == nil
    assert MyEnum.at([2,4,6], -1) == 6
    assert MyEnum.at([2,4,6], -2) == 4
    assert MyEnum.at([2,4,6], -3) == 2
    assert MyEnum.at([2,4,6], -4) == nil
  end
  test "at/3" do
    assert MyEnum.at([2,4,6], 4, :none) == :none
  end

  test "fetch!/2" do
    assert MyEnum.fetch!([2,4,6], 0) == {:ok, 2}
    assert MyEnum.fetch!([2,4,6], 2) == {:ok, 6}
    assert_raise(Enum.OutOfBoundsError, fn -> MyEnum.fetch!([2,4,6], 4) end)
  end
  test "fetch/2" do
    assert MyEnum.fetch([2,4,6], 0) == {:ok, 2}
    assert MyEnum.fetch([2,4,6], -3) == {:ok, 2}
    assert MyEnum.fetch([2,4,6], 2) == {:ok, 6}
    assert MyEnum.fetch([2,4,6], 4) == :error
  end

  test "concat/1" do
    assert MyEnum.concat([1..3,4..6,7..9]) == [1,2,3,4,5,6,7,8,9]
    assert MyEnum.concat([[1, [2], 3], [4], [5, 6]]) == [1,[2],3,4,5,6]
  end
  test "concat/2" do
    assert MyEnum.concat(1..3, 4..6) == [1,2,3,4,5,6]
    assert MyEnum.concat([1,2,3], [4,5,6]) == [1,2,3,4,5,6]
  end

  test "with_index/1" do
    assert MyEnum.with_index([:a, :b, :c]) == [a: 0, b: 1, c: 2]
    assert MyEnum.with_index([:a, :b, :c], 3) == [a: 3, b: 4, c: 5]
  end

  test "each/2" do
    fun = fn ->
      assert MyEnum.each(["some", "example"], fn x -> IO.puts(x) end)
    end
    assert capture_io(fun) == "some\nexample\n"
  end

  test "uniq/1" do
    assert MyEnum.uniq([1,2,3,3,2,1]) == [1,2,3]
  end

  test "uniq_by/2" do
    assert MyEnum.uniq_by([{1, :x}, {2, :y}, {1, :z}], fn {x, _} -> x end) == [{1, :x}, {2, :y}]
    assert MyEnum.uniq_by([a: {:tea, 2}, b: {:tea, 2}, c: {:coffee, 1}], fn {_, y} -> y end) == [a: {:tea, 2}, c: {:coffee, 1}]
  end

  test "take/2" do
    assert MyEnum.take([1,2,3], 2) == [1,2]
    assert MyEnum.take([1,2,3], 0) == []
    assert MyEnum.take([1,2,3], 10) == [1,2,3]
    assert MyEnum.take([1,2,3], -1) == [3]
  end

  test "take_every" do
    assert MyEnum.take_every(1..10, 2) == [1, 3, 5, 7, 9]
    assert MyEnum.take_every(1..10, 0) == []
    assert MyEnum.take_every([1, 2, 3], 1) == [1, 2, 3]
  end

  test "take_while" do
    assert MyEnum.take_while([1, 2, 3], fn x -> x < 3 end) == [1, 2]
  end

  test "dedup/1" do
    assert MyEnum.dedup([1, 2, 3, 3, 2, 1]) == [1, 2, 3, 2, 1]
    assert MyEnum.dedup([1, 1, 2, 2.0, :three, :three]) == [1, 2, 2.0, :three]
  end

  test "dedup_by/2" do
    assert MyEnum.dedup_by([{1, :a}, {2, :b}, {2, :c}, {1, :a}], fn {x, _} -> x end) == [{1, :a}, {2, :b}, {1, :a}]
    assert MyEnum.dedup_by([5, 1, 2, 3, 2, 1], fn x -> x > 2 end) == [5, 1, 3, 2]
  end

  test "chunk_by/2" do
    assert MyEnum.chunk_by([1, 2, 2, 3, 4, 4, 6, 7, 7], &(rem(&1, 2) == 1)) == [[1], [2, 2], [3], [4, 4, 6], [7, 7]]
  end

  test "chunk_every" do
    assert MyEnum.chunk_every([1, 2, 3, 4, 5, 6], 2) == [[1, 2], [3, 4], [5, 6]]
    #assert MyEnum.chunk_every([1, 2, 3, 4, 5, 6], 3, 2, :discard) == [[1, 2, 3], [3, 4, 5]]
    # assert MyEnum.chunk_every([1, 2, 3, 4, 5, 6], 3, 2, [7]) == [[1, 2, 3], [3, 4, 5], [5, 6, 7]]
    # assert MyEnum.chunk_every([1, 2, 3, 4], 3, 3, []) == [[1, 2, 3], [4]]
    # assert MyEnum.chunk_every([1, 2, 3, 4], 10) == [[1, 2, 3, 4]]
    # assert MyEnum.chunk_every([1, 2, 3, 4, 5], 2, 3, []) == [[1, 2], [4, 5]]
  end

  test "find" do
    assert MyEnum.find([2, 4, 6], fn x -> rem(x, 2) == 1 end) == nil
    assert MyEnum.find([2, 4, 6], 0, fn x -> rem(x, 2) == 1 end) == 0
    assert MyEnum.find([2, 3, 4], fn x -> rem(x, 2) == 1 end) == 3
  end

  test "find_index" do
    assert MyEnum.find_index([2, 4, 6], fn x -> rem(x, 2) == 1 end) == nil
    assert MyEnum.find_index([2, 3, 4], fn x -> rem(x, 2) == 1 end) == 1
  end

  test "find_value" do
    assert MyEnum.find_value([2, 4, 6], fn x -> rem(x, 2) == 1 end) == nil
    assert MyEnum.find_value([2, 3, 4], fn x -> rem(x, 2) == 1 end) == true
    assert MyEnum.find_value([1, 2, 3], "no bools!", &is_boolean/1) == "no bools!"
  end

  test "scan" do
    assert MyEnum.scan(1..5, 0, &(&1 + &2)) == [1, 3, 6, 10, 15]
    assert MyEnum.scan(1..5, 5, &(&1 + &2)) == [1, 3, 6, 10, 15] |> Enum.map(&(&1+5))
    assert MyEnum.scan(1..5, &(&1 + &2)) == [1, 3, 6, 10, 15]
  end

  test "group_by" do
    assert MyEnum.group_by(~w{ant buffalo cat dingo}, &String.length/1) == %{3 => ["ant", "cat"], 5 => ["dingo"], 7 => ["buffalo"]}
    assert MyEnum.group_by(~w{ant buffalo cat dingo}, &String.length/1, &String.first/1) == %{3 => ["a", "c"], 5 => ["d"], 7 => ["b"]}
  end

  test "flat_map" do
    assert MyEnum.flat_map([:a, :b, :c], fn x -> [x, x] end) == [:a, :a, :b, :b, :c, :c]
    assert MyEnum.flat_map([{1, 3}, {4, 6}], fn {x, y} -> x..y end) == [1, 2, 3, 4, 5, 6]
    assert MyEnum.flat_map([:a, :b, :c], fn x -> [[x]] end) == [[:a], [:b], [:c]]
  end

  test "flat_map_reduce" do
    assert  MyEnum.flat_map_reduce(1..100, 0, fn x, acc ->
              if acc < 3, do: {[x], acc + 1}, else: {:halt, acc}
            end) == {[1, 2, 3], 3}

    assert MyEnum.flat_map_reduce(1..5, 0, fn x, acc -> {[[x]], acc + x} end) == {[[1], [2], [3], [4], [5]], 15}
  end

  test "join" do
    assert MyEnum.join([1, 2, 3]) == "123"
    assert MyEnum.join([1, 2, 3], " = ") == "1 = 2 = 3"
  end

  test "map_join" do
    assert MyEnum.map_join([1, 2, 3], &(&1 * 2)) == "246"
    assert MyEnum.map_join([1, 2, 3], " = ", &(&1 * 2)) == "2 = 4 = 6"
  end

  test "intersperse" do
    assert MyEnum.intersperse([1, 2, 3], 0) == [1, 0, 2, 0, 3]
    assert MyEnum.intersperse([1], 0) == [1]
    assert MyEnum.intersperse([], 0) == []
  end

  test "into" do
    assert MyEnum.into([1, 2], []) == [1, 2]
    assert MyEnum.into([1, 2], [3, 4]) == [3, 4, 1, 2]
    assert MyEnum.into([a: 1, b: 2], %{}) == %{a: 1, b: 2}
    assert MyEnum.into(%{a: 1}, %{b: 2}) == %{a: 1, b: 2}
    assert MyEnum.into([a: 1, a: 2], %{}) == %{a: 2}
  end

  test "member?" do
    assert MyEnum.member?(1..10, 5) == true
    assert MyEnum.member?(1..10, 5.0) == false
    assert MyEnum.member?([1.0, 2.0, 3.0], 2) == false
    assert MyEnum.member?([1.0, 2.0, 3.0], 2.000) == true
    assert MyEnum.member?([:a, :b, :c], :d) == false
  end

  test "random" do
    :rand.seed(:exsplus, {101, 102, 103})
    assert MyEnum.random([1, 2, 3]) == 1
    assert MyEnum.random([1, 2, 3]) == 3
    assert MyEnum.random(1..1_000) == 556
  end

  test "slice/2" do
    assert MyEnum.slice(1..100, 5..10) == [6, 7, 8, 9, 10, 11]
    assert MyEnum.slice(1..10, 5..20) == [6, 7, 8, 9, 10]
    # last five elements (negative indexes)
    assert MyEnum.slice(1..30, -5..-1) == [26, 27, 28, 29, 30]
    # last five elements (mixed positive and negative indexes)
    assert MyEnum.slice(1..30, 25..-1) == [26, 27, 28, 29, 30]
    # out of bounds
    assert MyEnum.slice(1..10, 11..20) == []
    # index_range.first is greater than index_range.last
    assert MyEnum.slice(1..10, 6..5) == []
  end

  test "slice/3" do
    assert MyEnum.slice(1..100, 5, 10) == [6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
    # amount to take is greater than the number of elements
    assert MyEnum.slice(1..10, 5, 100) == [6, 7, 8, 9, 10]
    assert MyEnum.slice(1..10, 5, 0) == []
    # using a negative start index
    assert MyEnum.slice(1..10, -6, 3) == [5, 6, 7]
    # out of bound start index (positive)
    assert MyEnum.slice(1..10, 10, 5) == []
    # out of bound start index (negative)
    assert MyEnum.slice(1..10, -11, 5) == []
  end

  test "reverse_slice" do
    assert MyEnum.reverse_slice([1, 2, 3, 4, 5, 6], 2, 4) == [1, 2, 6, 5, 4, 3]
  end

  test "split" do
    assert MyEnum.split([1, 2, 3], 2) == {[1, 2], [3]}
    assert MyEnum.split([1, 2, 3], 10) == {[1, 2, 3], []}
    assert MyEnum.split([1, 2, 3], 0) == {[], [1, 2, 3]}
    assert MyEnum.split([1, 2, 3], -1) == {[1, 2], [3]}
    assert MyEnum.split([1, 2, 3], -5) == {[], [1, 2, 3]}
  end

  test "split_while" do
    assert MyEnum.split_while([1, 2, 3, 4], fn x -> x < 3 end) == {[1, 2], [3, 4]}
    assert MyEnum.split_while([1, 2, 3, 4], fn x -> x < 0 end) == {[], [1, 2, 3, 4]}
    assert MyEnum.split_while([1, 2, 3, 4], fn x -> x > 0 end) == {[1, 2, 3, 4], []}
  end

  test "split_with" do
    assert MyEnum.split_with([5, 4, 3, 2, 1, 0], fn x -> rem(x, 2) == 0 end) == {[4, 2, 0], [5, 3, 1]}
    assert MyEnum.split_with(%{a: 1, b: -2, c: 1, d: -3}, fn {_k, v} -> v < 0 end) == {[b: -2, d: -3], [a: 1, c: 1]}
    assert MyEnum.split_with(%{a: 1, b: -2, c: 1, d: -3}, fn {_k, v} -> v > 50 end) == {[], [a: 1, b: -2, c: 1, d: -3]}
    assert MyEnum.split_with(%{}, fn {_k, v} -> v > 50 end) == {[], []}
  end

end
