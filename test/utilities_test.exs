defmodule Utilities.Test do
  use ExUnit.Case
  doctest Utilities

  describe "Utilities.format_for_currency/1" do
    test "formats correctly for 3 digit amount" do
      assert Utilities.format_for_currency(453) == "$4.53"
    end

    test "formats correctly for 2 digit amount" do
      assert Utilities.format_for_currency(72) == "$0.72"
    end

    test "formats correctly for 1 digit amount" do
      assert Utilities.format_for_currency(5) == "$0.05"
    end
  end
end
