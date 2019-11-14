defmodule CoinStorage do
  @behaviour Access

  @coin_to_values %{
    quarter: 25,
    dime: 10,
    nickel: 5
  }

  defstruct wallet: [],
            tally: %{quarter: 0, dime: 0, nickel: 0},
            total: 0

  def add_coins(coin_storage, [hd | tl] = coins) do
    add_coins(add_coin(coin_storage, hd), tl)
  end

  def add_coins(coin_storage, []) do
    coin_storage
  end

  def add_coin(coin_storage, coin) do
    coin_storage = put_in(coin_storage.wallet, [coin | coin_storage.wallet])
    coin_storage = update_in(coin_storage, [Access.key(:tally), Access.key(coin.name)], &(&1 + 1))
    put_in(coin_storage.total, coin_storage.total + @coin_to_values[coin.name])
  end

  def remove_coins(coin_storage) do
    {coin_storage.wallet, %CoinStorage{}}
  end

  def remove_coin(coin_storage, coin) do
    coin_storage = put_in(coin_storage.wallet, coin_storage.wallet -- [coin])
    coin_storage = update_in(coin_storage, [Access.key(:tally), Access.key(coin.name)], &(&1 - 1))
    put_in(coin_storage.total, coin_storage.total - @coin_to_values[coin.name])
  end

  def get_and_remove_coin(coin_storage, coin) do
    {coin, remove_coin(coin_storage, coin)}
  end

  def remove_any(coin_storage) do
    [hd | _tl] = coin_storage.wallet
    get_and_remove_coin(coin_storage, hd)
  end

  @doc """
  requires: dime or nickel exists
  """
  def remove_highest_non_quarter_coin(coin_storage) do
    if coin_storage.tally.dime > 0 do
      get_and_remove_coin(coin_storage, Coin.createDime())
    else
      get_and_remove_coin(coin_storage, Coin.createNickel())
    end
  end

  def equal?(coin_storage_one, coin_storage_two) do
    Enum.sort(coin_storage_one.wallet) == Enum.sort(coin_storage_two.wallet) &&
      coin_storage_one.tally == coin_storage_two.tally &&
      coin_storage_one.total == coin_storage_two.total
  end

  def get_highest_non_quarter_coin(coin_storage) do
    case coin_storage.tally do
      %{quarter: _, dime: 0, nickel: 0} -> nil
      %{quarter: _, dime: 0, nickel: _} -> Coin.createNickel()
      %{quarter: _, dime: _, nickel: _} -> Coin.createDime()
    end
  end
end
