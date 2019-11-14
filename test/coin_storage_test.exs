defmodule CoinStorage.Test do
  use ExUnit.Case
  doctest CoinStorage

  @nickel %Coin{weight: 5.0, name: :nickel}
  @dime %Coin{weight: 2.268, name: :dime}
  @quarter %Coin{weight: 5.670, name: :quarter}

  describe "CoinStorage.add_coin/2" do
    test "default coin storage has nothing in it" do
      coin_storage = %CoinStorage{}
      assert coin_storage.wallet == []
      assert coin_storage.tally == %{quarter: 0, dime: 0, nickel: 0}
      assert coin_storage.total == 0
    end

    test "If quarter is added to coin storage then wallet has quarter" do
      coin_storage = %CoinStorage{}
      coin_storage = CoinStorage.add_coin(coin_storage, @quarter)
      assert coin_storage.wallet == [@quarter]
      assert coin_storage.tally == %{quarter: 1, dime: 0, nickel: 0}
      assert coin_storage.total == 25
    end
  end

  describe "CoinStorage.add_coins/2" do
    test "If a quarter, dime and nickel are added to coin storage then wall has one more of each coin" do
      coin_storage = %CoinStorage{}
      coin_storage = CoinStorage.add_coins(coin_storage, [@quarter, @dime, @nickel])
      assert Enum.sort(coin_storage.wallet) == Enum.sort([@quarter, @dime, @nickel])
      assert coin_storage.tally == %{quarter: 1, dime: 1, nickel: 1}
      assert coin_storage.total == 40
    end
  end

  describe "CoinStorage.remove_coins/1" do
    test "returns all coins in wallet" do
      coin_storage = %CoinStorage{
        wallet: [@quarter, @dime, @nickel],
        tally: %{quarter: 1, dime: 1, nickel: 1},
        total: 40
      }

      {coins, coin_storage} = CoinStorage.remove_coins(coin_storage)
      assert Enum.sort(coins) == Enum.sort([@quarter, @dime, @nickel])
      assert coin_storage.wallet == []
      assert coin_storage.tally == %{quarter: 0, dime: 0, nickel: 0}
      assert coin_storage.total == 0
    end
  end

  describe "CoinStorage.remove_coin/2" do
    test "If quarter is removed from coin storage then wall has one less quarter" do
      coin_storage = %CoinStorage{
        wallet: [@quarter],
        tally: %{quarter: 1, dime: 0, nickel: 0},
        total: 25
      }

      coin_storage = CoinStorage.remove_coin(coin_storage, @quarter)
      assert coin_storage.wallet == []
      assert coin_storage.tally == %{quarter: 0, dime: 0, nickel: 0}
      assert coin_storage.total == 0
    end
  end

  describe "CoinStorage.remove_and_get_coin/2" do
    test "If quarter is removed from coin storage then wall has one less quarter" do
      coin_storage = %CoinStorage{
        wallet: [@quarter],
        tally: %{quarter: 1, dime: 0, nickel: 0},
        total: 25
      }

      {coin, coin_storage} = CoinStorage.get_and_remove_coin(coin_storage, @quarter)
      assert coin_storage.wallet == []
      assert coin_storage.tally == %{quarter: 0, dime: 0, nickel: 0}
      assert coin_storage.total == 0
      assert coin == @quarter
    end
  end

  describe "CoinStorage.remove_any/1" do
    test "removes a coin from storage" do
      coin_storage = %CoinStorage{
        wallet: [@quarter, @dime, @nickel],
        tally: %{quarter: 1, dime: 1, nickel: 1},
        total: 40
      }

      {coin, coin_storage} = CoinStorage.remove_any(coin_storage)
      assert coin == @quarter || coin == @dime || coin == @nickel
      assert get_in(coin_storage, [Access.key(:tally), Access.key(coin.name)]) == 0
    end
  end

  describe "CoinStorage.remove_highest_non_quarter_coin/1" do
    test "removes dime from storage when storage has dime" do
      coin_storage = %CoinStorage{
        wallet: [@quarter, @dime, @nickel],
        tally: %{quarter: 1, dime: 1, nickel: 1},
        total: 40
      }

      {coin, coin_storage} = CoinStorage.remove_highest_non_quarter_coin(coin_storage)
      assert coin == @dime
      assert CoinStorage.equal?(coin_storage, %CoinStorage{
        wallet: [@quarter, @nickel],
        tally: %{quarter: 1, dime: 0, nickel: 1},
        total: 30
      })
    end
  end

  describe "CoinStorage.equal?/2" do
    test "considers two coin storages equal even if their wallets have coins in different order" do
      coin_storage_one = %CoinStorage{
        wallet: [@quarter, @dime, @nickel],
        tally: %{quarter: 1, dime: 1, nickel: 1},
        total: 40
      }

      coin_storage_two = %CoinStorage{
        wallet: [@dime, @quarter, @nickel],
        tally: %{quarter: 1, dime: 1, nickel: 1},
        total: 40
      }

      assert CoinStorage.equal?(coin_storage_one, coin_storage_two) == true
    end

    test "considers two coin storages not equal if their wallets have different coins in them" do
      coin_storage_one = %CoinStorage{
        wallet: [@dime, @dime, @dime, @nickel, @nickel],
        tally: %{quarter: 0, dime: 3, nickel: 2},
        total: 40
      }

      coin_storage_two = %CoinStorage{
        wallet: [@dime, @quarter, @nickel],
        tally: %{quarter: 1, dime: 1, nickel: 1},
        total: 40
      }

      assert CoinStorage.equal?(coin_storage_one, coin_storage_two) == false
    end
  end

  describe "CoinStorage.get_highest_not_quarter_coin/2" do
    test "returns dime from storage when storage has dime" do
      coin_storage = %CoinStorage{
        wallet: [@quarter, @dime, @nickel],
        tally: %{quarter: 1, dime: 1, nickel: 1},
        total: 40
      }

      coin = CoinStorage.get_highest_non_quarter_coin(coin_storage)
      assert coin == @dime
    end

    test "returns nickel from storage when storage doesn't have dime" do
      coin_storage = %CoinStorage{
        wallet: [@quarter, @nickel],
        tally: %{quarter: 1, dime: 0, nickel: 1},
        total: 30
      }

      coin = CoinStorage.get_highest_non_quarter_coin(coin_storage)
      assert coin == @nickel
    end

    test "returns nil from storage when neither dime or nickel exist" do
      coin_storage = %CoinStorage{
        wallet: [@quarter, @nickel],
        tally: %{quarter: 1, dime: 0, nickel: 0},
        total: 25
      }

      coin = CoinStorage.get_highest_non_quarter_coin(coin_storage)
      assert coin == nil
    end
  end
end
