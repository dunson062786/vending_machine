defmodule VendingMachine do
  import Utilities
  @nickel 5.0
  @dime 2.268
  @quarter 5.670

  defstruct coin_return: [],
            bank: %CoinStorage{},
            inventory: [],
            staging: %CoinStorage{},
            display: nil,
            bin: [],
            grid: %{cola: false, chips: false, candy: false},
            ledger: %{cola: 100, chips: 50, candy: 65},
            flag: false

  def insert_coin(vending_machine, coin) do
    case coin.weight do
      value when value in [@nickel, @dime, @quarter] ->
        vending_machine =
          put_in(vending_machine.staging, CoinStorage.add_coin(vending_machine.staging, coin))

        put_in(
          vending_machine.display,
          format_for_currency(vending_machine.staging.total)
        )

      _ ->
        put_in(
          vending_machine.coin_return,
          [coin| vending_machine.coin_return]
        )
    end
  end

  def select_product(vending_machine, product) do
    vending_machine
    |> select_item_in_grid(product)
    |> process_transaction()
  end

  def check_display(vending_machine) do
      if (Enum.member?(
        ["THANK YOU", "PRICE $1.00", "PRICE $0.65", "PRICE $0.50", "SOLD OUT"],
        vending_machine.display
      )) do
        if vending_machine.staging.wallet == [] do
          change_display(vending_machine)
        else
          amount_inserted = format_for_currency(vending_machine.staging.total)

          {put_in(vending_machine.display, amount_inserted), vending_machine.display}
        end
      else
        if vending_machine.display == nil do
          change_display(vending_machine)
        else
          {vending_machine, vending_machine.display}
        end
      end
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
    price = get_price_of_selected(vending_machine)
    amount_owed = vending_machine.staging.total - price
    cond do
      sold_out(vending_machine) ->
        vending_machine = deselect_everything(vending_machine)
        put_in(vending_machine.display, "SOLD OUT")
      vending_machine.staging.total < price ->
        put_in(vending_machine.display, "PRICE #{format_for_currency(price)}")
      amount_owed == 0 || can_make_change(vending_machine) ->
        do_process(vending_machine, amount_owed)
      true ->
        vending_machine = transfer_coins(vending_machine, :staging, :coin_return)
        put_in(vending_machine.display, "EXACT CHANGE ONLY")
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
    {coins, empty_staging} = CoinStorage.remove_coins(vending_machine.staging)
    vending_machine =
      put_in(vending_machine.bank, CoinStorage.add_coins(vending_machine.bank, coins))

    put_in(vending_machine.staging, empty_staging)
  end

  @doc """
  requires: can_make_change(vending_machine) is true
  ensures: amount_owed is sent to coin_return
  """
  def give_change(vending_machine, amount_owed) do
    cond do
      amount_owed >= 25 ->
        {coin, _rest} = CoinStorage.remove_any(vending_machine.staging)
        vending_machine = transfer_coin(vending_machine, :staging, :coin_return, coin)
        give_change(vending_machine, amount_owed - get_value_of_coin(coin))

      amount_owed >= 10 ->
        coin = CoinStorage.get_highest_non_quarter_coin(vending_machine.bank)
        vending_machine = transfer_coin(vending_machine, :bank, :coin_return, coin)
        give_change(vending_machine, amount_owed - get_value_of_coin(coin))

      amount_owed >= 5 ->
        transfer_coin(vending_machine, :bank, :coin_return, Coin.createNickel())

      true ->
        vending_machine
    end
  end

  @doc """
  If the bank return any multiple of 5c up to 20c then there is enough money to make change
  since you could always return coins from staging until you get within that range.
  """
  def can_make_change(vending_machine) do
    number_of_nickels = vending_machine.bank.tally.nickel
    number_of_dimes = vending_machine.bank.tally.dime

    number_of_nickels > 3 || (number_of_nickels > 1 && number_of_dimes > 0) ||
      (number_of_nickels == 1 && number_of_dimes > 1)
  end

  @doc """
  requires: nickel or dime exists in vending machine bank
  ensures: returns dime from bank if possible. Otherwise it returns a nickel.
  """
  def remove_highest_non_quarter_coin(vending_machine) do
    if Enum.any?(vending_machine.bank, fn coin -> coin == Coin.createDime() end) do
      {Coin.createDime(),
       put_in(vending_machine.bank, vending_machine.bank -- [Coin.createDime()])}
    else
      {Coin.createNickel(),
       put_in(vending_machine.bank, vending_machine.bank -- [Coin.createNickel()])}
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

  def transfer_coins(vending_machine, from, to) do
    {coins, coin_storage} = CoinStorage.remove_coins(get_in(vending_machine, [Access.key(from)]))
    vending_machine = if to == :coin_return do
      put_in(vending_machine.coin_return, vending_machine.coin_return ++ coins)
    else
      put_in(vending_machine, [Access.key(to)], coins)
    end
    put_in(vending_machine, [Access.key(from)], coin_storage)
  end

  def transfer_coin(vending_machine, from, to, coin) do
    vending_machine =
      put_in(
        vending_machine,
        [Access.key(from)],
        CoinStorage.remove_coin(get_in(vending_machine, [Access.key(from)]), coin)
      )

    if to == :coin_return do
      put_in(vending_machine.coin_return, [coin | vending_machine.coin_return])
    else
      put_in(
        vending_machine,
        [Access.key(to)],
        CoinStorage.add_coin(get_in(vending_machine, [Access.key(to)]), coin)
      )
    end
  end

  def change_display(vending_machine) do
    if can_make_change(vending_machine) do
      {put_in(vending_machine.display, "INSERT COIN"), (vending_machine.display || "INSERT COIN")}
    else
      {put_in(vending_machine.display, "EXACT CHANGE ONLY"), (vending_machine.display || "EXACT CHANGE ONLY")}
    end
  end

  def do_process(vending_machine, amount_owed) do
    product = %Product{name: get_selected(vending_machine)}

    vending_machine =
      put_in(vending_machine.inventory, vending_machine.inventory -- [product])

    vending_machine = put_in(vending_machine.bin, [product | vending_machine.bin])
    vending_machine = give_change(vending_machine, amount_owed)
    vending_machine = move_coins_to_bank(vending_machine)
    put_in(vending_machine.display, "THANK YOU")
  end

end
