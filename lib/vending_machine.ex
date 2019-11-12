defmodule VendingMachine do
  import Utilities
  @nickel 5.0
  @dime 2.268
  @quarter 5.670

  defstruct coin_return: [],
            bank: [],
            inventory: [],
            staging: [],
            display: nil,
            bin: [],
            grid: %{cola: false, chips: false, candy: false},
            ledger: %{cola: 100, chips: 50, candy: 65},
            flag: false

  def insert_coin(vending_machine, coin) do
    case coin.weight do
      value when value in [@nickel, @dime, @quarter] ->
        vending_machine = put_in(vending_machine.staging, [coin | vending_machine.staging])

        put_in(
          vending_machine.display,
          format_for_currency(get_value_of_coins(vending_machine.staging))
        )

      _ ->
        put_in(vending_machine.coin_return, [coin | vending_machine.coin_return])
    end
  end

  def select_product(vending_machine, product) do
    vending_machine
    |> select_item_in_grid(product)
    |> process_transaction()
  end

  def check_display(vending_machine) do
    cond do
      vending_machine.display == "THANK YOU" ->
        {put_in(vending_machine.display, "INSERT COIN"), "THANK YOU"}

      vending_machine.display == "PRICE $1.00" ->
        if vending_machine.staging == [] do
          if can_make_change(vending_machine) do
            {put_in(vending_machine.display, "INSERT COIN"), "PRICE $1.00"}
          else
            {put_in(vending_machine.display, "EXACT CHANGE ONLY"), "PRICE $1.00"}
          end
        else
          amount_inserted =
            vending_machine.staging
            |> get_value_of_coins()
            |> format_for_currency()

          {put_in(vending_machine.display, amount_inserted), "PRICE $1.00"}
        end

      vending_machine.display == "PRICE $0.65" ->
        if vending_machine.staging == [] do
          if can_make_change(vending_machine) do
            {put_in(vending_machine.display, "INSERT COIN"), "PRICE $0.65"}
          else
            {put_in(vending_machine.display, "EXACT CHANGE ONLY"), "PRICE $0.65"}
          end
        else
          amount_inserted =
            vending_machine.staging
            |> get_value_of_coins()
            |> format_for_currency()

          {put_in(vending_machine.display, amount_inserted), "PRICE $0.65"}
        end

      vending_machine.display == "PRICE $0.50" ->
        if vending_machine.staging == [] do
          if can_make_change(vending_machine) do
            {put_in(vending_machine.display, "INSERT COIN"), "PRICE $0.50"}
          else
            {put_in(vending_machine.display, "EXACT CHANGE ONLY"), "PRICE $0.50"}
          end
        else
          amount_inserted =
            vending_machine.staging
            |> get_value_of_coins()
            |> format_for_currency()

          {put_in(vending_machine.display, amount_inserted), "PRICE $0.50"}
        end

      vending_machine.display == "SOLD OUT" ->
        if vending_machine.staging == [] do
          if can_make_change(vending_machine) do
            {put_in(vending_machine.display, "INSERT COIN"), "SOLD OUT"}
          else
            {put_in(vending_machine.display, "EXACT CHANGE ONLY"), "SOLD OUT"}
          end
        else
          amount_inserted =
            vending_machine.staging
            |> get_value_of_coins()
            |> format_for_currency()

          {put_in(vending_machine.display, amount_inserted), "SOLD OUT"}
        end

      vending_machine.display == nil ->
        if can_make_change(vending_machine) do
          {put_in(vending_machine.display, "INSERT COIN"), "INSERT COIN"}
        else
          {put_in(vending_machine.display, "EXACT CHANGE ONLY"), "EXACT CHANGE ONLY"}
        end

      true ->
        {vending_machine, vending_machine.display}
    end
  end

  def deselect_selected(vending_machine, product) do
    %VendingMachine{
      vending_machine
      | grid: Map.replace!(vending_machine.grid, product, false)
    }
  end

  def select_item_in_grid(vending_machine, product) do
    put_in(vending_machine, [Access.key(:grid), Access.key(product)], true)
  end

  def deselect_everything(vending_machine) do
    put_in(
      vending_machine.grid,
      Enum.into(vending_machine.grid, %{}, fn {k, _v} -> {k, false} end)
    )
  end

  def process_transaction(vending_machine) do
    if sold_out(vending_machine) do
      vending_machine = deselect_everything(vending_machine)
      put_in(vending_machine.display, "SOLD OUT")
    else
      price = get_price_of_selected(vending_machine)

      value_of_coins = get_value_of_coins(vending_machine.staging)

      if value_of_coins < price do
        put_in(vending_machine.display, "PRICE #{format_for_currency(price)}")
      else
        amount_owed = value_of_coins - price

        if amount_owed == 0 || can_make_change(vending_machine) do
          product = %Product{name: get_selected(vending_machine)}

          vending_machine =
            put_in(vending_machine.inventory, vending_machine.inventory -- [product])

          vending_machine = put_in(vending_machine.bin, [product | vending_machine.bin])
          vending_machine = give_change(vending_machine, value_of_coins - price)
          vending_machine = move_coins_to_bank(vending_machine)
          put_in(vending_machine.display, "THANK YOU")
        else
          # return coins and display "EXACT CHANGE ONLY"
          vending_machine = put_in(vending_machine.coin_return, vending_machine.staging)
          vending_machine = put_in(vending_machine.staging, [])
          put_in(vending_machine.display, "EXACT CHANGE ONLY")
        end
      end
    end
  end

  def sold_out(vending_machine) do
    selected = get_selected(vending_machine)
    Enum.empty?(Enum.filter(vending_machine.inventory, fn x -> x.name == selected end))
  end

  def get_selected(vending_machine) do
    case vending_machine.grid do
      %{cola: true, chips: false, candy: false} -> :cola
      %{cola: false, chips: true, candy: false} -> :chips
      %{cola: false, chips: false, candy: true} -> :candy
      _ -> nil
    end
  end

  def move_coins_to_bank(vending_machine) do
    vending_machine =
      put_in(vending_machine.bank, vending_machine.bank ++ vending_machine.staging)

    put_in(vending_machine.staging, [])
  end

  @doc """
  requires: can_make_change(vending_machine) is true
  ensures: amount_owed is sent to coin_return
  """
  def give_change(vending_machine, amount_owed) do
    cond do
      amount_owed >= 25 ->
        [last_coin | rest] = vending_machine.staging
        vending_machine = put_in(vending_machine.staging, rest)

        vending_machine =
          put_in(
            vending_machine.coin_return,
            [last_coin | vending_machine.coin_return]
          )

        give_change(vending_machine, amount_owed - get_value_of_coin(last_coin))

      amount_owed >= 10 ->
        {highest_non_quarter_coin, vending_machine} =
          remove_highest_non_quarter_coin(vending_machine)

        vending_machine =
          put_in(
            vending_machine.coin_return,
            [highest_non_quarter_coin | vending_machine.coin_return]
          )

        give_change(vending_machine, amount_owed - get_value_of_coin(highest_non_quarter_coin))

      amount_owed >= 5 ->
        vending_machine =
          put_in(vending_machine.bank, vending_machine.bank -- [%Coin{weight: @nickel}])

        vending_machine =
          put_in(
            vending_machine.coin_return,
            [%Coin{weight: @nickel} | vending_machine.coin_return]
          )

        give_change(vending_machine, amount_owed - 5)

      true ->
        vending_machine
    end
  end

  @doc """
  If the bank return any multiple of 5c up to 20c then there is enough money to make change
  since you could always return coins from staging until you get within that range.
  """
  def can_make_change(vending_machine) do
    number_of_nickels =
      Enum.count(vending_machine.bank, fn coin -> coin == %Coin{weight: @nickel} end)

    number_of_dimes =
      Enum.count(vending_machine.bank, fn coin -> coin == %Coin{weight: @dime} end)

    number_of_nickels > 3 || (number_of_nickels > 1 && number_of_dimes > 0) ||
      (number_of_nickels == 1 && number_of_dimes > 1)
  end

  @doc """
  requires: nickel or dime exists in vending machine bank
  ensures: returns dime from bank if possible. Otherwise it returns a nickel.
  """
  def remove_highest_non_quarter_coin(vending_machine) do
    if Enum.any?(vending_machine.bank, fn coin -> coin == %Coin{weight: @dime} end) do
      {%Coin{weight: @dime},
       put_in(vending_machine.bank, vending_machine.bank -- [%Coin{weight: @dime}])}
    else
      {%Coin{weight: @nickel},
       put_in(vending_machine.bank, vending_machine.bank -- [%Coin{weight: @nickel}])}
    end
  end

  def return_coins(vending_machine) do
    vending_machine =
      put_in(vending_machine.coin_return, vending_machine.coin_return ++ vending_machine.staging)

    put_in(vending_machine.staging, [])
  end

  def get_price_of_selected(vending_machine) do
    get_in(vending_machine, [Access.key(:ledger), Access.key(get_selected(vending_machine))])
  end
end
