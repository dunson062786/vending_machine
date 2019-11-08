defmodule VendingMachineTest do
  use ExUnit.Case
  doctest VendingMachine

  @invalid %Coin{weight: 2.5}
  @nickel %Coin{weight: 5.0}
  @dime %Coin{weight: 2.268}
  @quarter %Coin{weight: 5.670}

  test "Add invalid coin to Vending machine with $0 displays 'INSERT COIN' and returns invalid coin" do
    VendingMachine.amount(0, @invalid) == {"INSERT COIN", @invalid}
  end

  test "Add nickel to Vending machine with $0 displays '0.05' keeps nickel" do
    VendingMachine.amount(0, @nickel) == {"0.05", nil}
  end

  test "Add invalid coin to Vending machine with $0.25 displays '0.25' and returns invalid coin" do
    VendingMachine.amount(0.25, @invalid) == {"0.25", @invalid}
  end

  test "Add nickel to Vending machine with $0.25 displays '0.25' and keeps nickel" do
    VendingMachine.amount(0.25, @nickel) == {"0.30", nil}
  end
end
