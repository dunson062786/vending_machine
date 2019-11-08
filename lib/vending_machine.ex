defmodule VendingMachine do
  @nickel 5.0
  @dime 2.268
  @quarter 5.670

  @spec amount(pos_integer, %Coin{}) :: String.t()
  def amount(total, coin) do
    case coin.weight do
      @nickel ->
        {total + 0.05, nil}

      @dime ->
        {total + 0.1, nil}

      @quarter ->
        {total + 0.25, nil}

      _ ->
        if total == 0 do
          {"INSERT COIN", coin}
        else
          {total, coin}
        end
    end
  end
end
