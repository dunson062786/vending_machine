defmodule Utilities do
  @nickel 5.0
  @dime 2.268
  @quarter 5.670

  def get_value_of_coins(list) do
    Enum.reduce(list, 0, &(get_value_of_coin(&1) + &2))
  end

  def get_value_of_coin(coin) do
    case coin.weight do
      @nickel -> 5
      @dime -> 10
      @quarter -> 25
      _ -> 0
    end
  end

  def format_for_currency(amount) do
    dollar_amount = div(amount, 100)
    cent_amount = rem(amount, 100)
    "$#{dollar_amount}.#{String.pad_leading(Integer.to_string(cent_amount), 2, "0")}"
  end
end
