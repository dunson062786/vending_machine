defmodule VendingMachineTest do
  use ExUnit.Case
  doctest VendingMachine

  @invalid %Coin{weight: 2.5}
  @nickel %Coin{weight: 5.0}
  @dime %Coin{weight: 2.268}
  @quarter %Coin{weight: 5.670}

  test "Add invalid coin to Vending machine with $0 displays 'INSERT COIN' and returns invalid coin" do
    oldVm = %VendingMachine{}
    newVm = VendingMachine.amount(oldVm, @invalid)
    expected = %{oldVm | coin_return: [@invalid]}
    assert newVm == expected
  end

  test "Add nickel to Vending machine with $0 displays '0.05' and keeps nickel" do
    oldVm = %VendingMachine{}
    newVm = VendingMachine.amount(oldVm, @nickel)
    expected = %{oldVm | display: "0.05", staging: [@nickel]}
    assert newVm == expected
  end

  test "Add invalid coin to Vending machine with $0.25 displays '0.25' and returns invalid coin" do
    oldVm = %VendingMachine{staging: [@quarter]}
    newVm = VendingMachine.amount(oldVm, @invalid)
    expected = %{oldVm | coin_return: [@invalid]}
    assert newVm == expected
  end

  test "Add nickel to Vending machine with $0.25 displays '0.30' and keeps nickel" do
    oldVm = %VendingMachine{staging: [@quarter]}
    newVm = VendingMachine.amount(oldVm, @nickel)
    expected = %{oldVm | display: "0.3", staging: [@quarter, @nickel]}
    assert newVm == expected
  end

  test "selects item when selected for first time" do
    vm = VendingMachine.select(%VendingMachine{}, "cola")
    assert vm.grid[:cola] == true
    vm = VendingMachine.select(%VendingMachine{}, "chips")
    assert vm.grid[:chips] == true
    vm = VendingMachine.select(%VendingMachine{}, "candy")
    assert vm.grid[:candy] == true
  end

  test "deselects item when new item is selected" do
    vm = %VendingMachine{grid: %{%VendingMachine{}.grid | cola: true}}
    vm = VendingMachine.select(vm, "chips")
    assert vm.grid[:cola] == false
    vm = %VendingMachine{grid: %{%VendingMachine{}.grid | chips: true}}
    vm = VendingMachine.select(vm, "candy")
    assert vm.grid[:chips] == false
    vm = %VendingMachine{grid: %{%VendingMachine{}.grid | candy: true}}
    vm = VendingMachine.select(vm, "chips")
    assert vm.grid[:candy] == false
  end

  test "deselects item if selected again" do
    vm = %VendingMachine{grid: %{%VendingMachine{}.grid | cola: true}}
    vm = VendingMachine.select(vm, "cola")
    assert vm.grid[:cola] == false
    vm = %VendingMachine{grid: %{%VendingMachine{}.grid | chips: true}}
    vm = VendingMachine.select(vm, "chips")
    assert vm.grid[:chips] == false
    vm = %VendingMachine{grid: %{%VendingMachine{}.grid | candy: true}}
    vm = VendingMachine.select(vm, "candy")
    assert vm.grid[:candy] == false
  end
end
