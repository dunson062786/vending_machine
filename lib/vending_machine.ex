defmodule VendingMachine do
  @nickel 5.0
  @dime 2.268
  @quarter 5.670

  defstruct [
    {:coin_return, []},
    {:bank, []},
    {:inventory, nil},
    {:staging, []},
    {:display, "INSERT COIN"}
  ]

  @spec amount(%VendingMachine{}, %Coin{}) :: %VendingMachine{}
  def amount(vending_machine, coin) do
    case coin.weight do
      @nickel ->
        staging = vending_machine.staging ++ [coin]
        %{vending_machine | staging: staging, display: Float.to_string(add_coins(staging))}

      @dime ->
        staging = vending_machine.staging ++ [coin]
        %{vending_machine | staging: staging, display: Float.to_string(add_coins(staging))}

      @quarter ->
        staging = vending_machine.staging ++ [coin]
        %{vending_machine | staging: staging, display: Float.to_string(add_coins(staging))}

      _ ->
        coin_return = vending_machine.coin_return ++ [coin]

        if vending_machine.staging == 0 do
          %{vending_machine | display: "INSERT COIN", coin_return: coin_return}
        else
          %{vending_machine | coin_return: coin_return}
        end
    end
  end

  defp add_coins([hd | tl]) do
    total = get_value_of_coin(hd) + add_coins(tl)
  end

  defp add_coins([]) do
    0
  end

  defp get_value_of_coin(coin) do
    case coin.weight do
      @nickel -> 0.05
      @dime -> 0.10
      @quarter -> 0.25
      _ -> 0
    end
  end
end
