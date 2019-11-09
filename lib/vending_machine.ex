defmodule VendingMachine do
  @nickel 5.0
  @dime 2.268
  @quarter 5.670

  defstruct [
    {:coin_return, []},
    {:bank, []},
    {:inventory, []},
    {:staging, []},
    {:display, "INSERT COIN"},
    {:bin, []},
    {:grid, %{cola: false, chips: false, candy: false}}
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

  def select(vending_machine, name) do
    selected = vending_machine.grid[name]

    if selected do
      %{vending_machine | grid: Map.replace!(%VendingMachine{}.grid, name, selected)}
    else
      if get_value_of_coins(vending_machine.staging) >= 1.0 do
        if Enum.any?(vending_machine.inventory) do
          remove_product_from_inventory(vending_machine, name)
        end
      else
        %{vending_machine | grid: Map.replace!(%VendingMachine{}.grid, name, selected)}
      end
    end
  end

  def remove_product_from_inventory(vm, name) do
    product = Enum.find(vm.inventory, fn x -> x.name == name end)
    newInventory = vm.inventory -- [product]
    newBin = vm.bin ++ [product]
    %VendingMachine{inventory: newInventory, bin: newBin}
  end

  defp add_coins([hd | tl]) do
    total = get_value_of_coin(hd) + add_coins(tl)
  end

  defp add_coins([]) do
    0
  end

  def get_value_of_coins(list) do
    Enum.reduce(list, 0, &(VendingMachine.get_value_of_coin(&1) + &2))
  end

  def get_value_of_coin(coin) do
    case coin.weight do
      @nickel -> 0.05
      @dime -> 0.10
      @quarter -> 0.25
      _ -> 0
    end
  end
end
