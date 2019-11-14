defmodule Coin.Test do
  use ExUnit.Case
  import Utilities
  doctest Coin

  describe "Coin.createQuarter/1" do
    test "createQuarter/1" do
      assert Coin.createQuarter() == %Coin{weight: 5.670, name: :quarter}
    end

    test "createDime/1" do
      assert Coin.createDime() == %Coin{weight: 2.268, name: :dime}
    end

    test "createNickel/1" do
      assert Coin.createNickel() == %Coin{weight: 5.0, name: :nickel}
    end
  end
end
