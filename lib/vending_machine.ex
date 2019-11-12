defmodule VendingMachine do
  import Utilities
  @nickel 5.0
  @dime 2.268
  @quarter 5.670

  defstruct coin_return: [],
            bank: [],
            inventory: [],
            staging: [],
            display: "INSERT COIN",
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
    selected = get_in(vending_machine, [Access.key(:grid), Access.key(product)])

    if selected do
      deselect_selected(vending_machine, product)
    else
      vending_machine
      |> select_item_in_grid(product)
      |> process_transaction()
    end
  end

  def check_display(vending_machine) do
    case vending_machine.display do
      "THANK YOU" ->
        {put_in(vending_machine.display, "INSERT COIN"), "THANK YOU"}

      _ ->
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
    vending_machine = deselect_everything(vending_machine)
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
      {price, display_price} =
        vending_machine
        |> get_selected()
        |> get_price()

      value_of_coins = get_value_of_coins(vending_machine.staging)

      if value_of_coins < price do
        put_in(vending_machine.display, "PRICE #{display_price}")
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
          # return last coin
          [last_coin | rest] = vending_machine.staging
          vending_machine = put_in(vending_machine.staging, rest)

          vending_machine =
            put_in(vending_machine.coin_return, [last_coin | vending_machine.coin_return])

          if amount_owed == get_value_of_coin(last_coin) do
            # coincidentally that was the correct change hence give product and store the money
            product = %Product{name: get_selected(vending_machine)}

            vending_machine =
              put_in(vending_machine.inventory, vending_machine.inventory -- [product])

            vending_machine = put_in(vending_machine.bin, [product | vending_machine.bin])
            vending_machine = move_coins_to_bank(vending_machine)
            put_in(vending_machine.display, "THANK YOU")
          else
            vending_machine
          end
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
    end
  end

  def get_price(product) do
    case product do
      :cola -> {100, "$1.00"}
      :chips -> {50, "$0.50"}
      :candy -> {65, "$0.65"}
    end
  end

  def move_coins_to_bank(vending_machine) do
    vending_machine =
      put_in(vending_machine.bank, vending_machine.bank ++ vending_machine.staging)

    put_in(vending_machine.staging, [])
  end

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

  def can_make_change(vending_machine) do
    number_of_nickels =
      Enum.count(vending_machine.bank, fn coin -> coin == %Coin{weight: @nickel} end)

    number_of_dimes =
      Enum.count(vending_machine.bank, fn coin -> coin == %Coin{weight: @dime} end)

    number_of_nickels > 3 || (number_of_nickels > 1 && number_of_dimes > 0) ||
      (number_of_nickels == 1 && number_of_dimes > 1)
  end

  def remove_highest_non_quarter_coin(vending_machine) do
    if Enum.any?(vending_machine.bank, fn coin -> coin == %Coin{weight: @dime} end) do
      {%Coin{weight: @dime},
       put_in(vending_machine.bank, vending_machine.bank -- [%Coin{weight: @dime}])}
    else
      {%Coin{weight: @nickel},
       put_in(vending_machine.bank, vending_machine.bank -- [%Coin{weight: @nickel}])}
    end
  end
end
