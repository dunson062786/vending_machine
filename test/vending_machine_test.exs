defmodule VendingMachine.Test do
  use ExUnit.Case
  import Utilities
  doctest VendingMachine

  @invalid %Coin{weight: 2.5}
  @nickel %Coin{weight: 5.0}
  @dime %Coin{weight: 2.268}
  @quarter %Coin{weight: 5.670}

  describe "VendingMachine.insert_coin/2" do
    test "Adding valid coin to vending machine updates staging" do
      vm = %VendingMachine{}
      vm = VendingMachine.insert_coin(vm, @quarter)
      assert vm.staging == [@quarter]
    end

    test "Adding invalid coin updates coin_return" do
      vm = %VendingMachine{}
      vm = VendingMachine.insert_coin(vm, @invalid)
      assert vm.coin_return == [@invalid]
    end

    test "If staging is empty and you insert an invalid coin vending machine still displays 'INSERT COIN'" do
      vm = %VendingMachine{}
      vm = VendingMachine.insert_coin(vm, @invalid)
      {_vm, message} = VendingMachine.check_display(vm)
      assert message == "INSERT COIN"
    end

    test "If staging is empty and you insert a nickel vending machine displays $0.05" do
      vm = %VendingMachine{}
      vm = VendingMachine.insert_coin(vm, @nickel)
      {_vm, message} = VendingMachine.check_display(vm)
      assert message == "$0.05"
    end

    test "If staging is empty and you insert a nickel vending machine displays $0.10" do
      vm = %VendingMachine{}
      vm = VendingMachine.insert_coin(vm, @dime)
      {_vm, message} = VendingMachine.check_display(vm)
      assert message == "$0.10"
    end

    test "If staging is empty and you insert a quarter vending machine displays $0.25" do
      vm = %VendingMachine{}
      vm = VendingMachine.insert_coin(vm, @quarter)
      {_vm, message} = VendingMachine.check_display(vm)
      assert message == "$0.25"
    end
  end

  describe "VendingMachine.select_product/2 grid functionality" do
    setup do
      %{
        vending_machine: %VendingMachine{
          inventory: [
            %Product{name: :cola},
            %Product{name: :chips},
            %Product{name: :candy}
          ]
        }
      }
    end

    test "selects cola if not sold out and selected for the first time", %{vending_machine: vm} do
      vm = VendingMachine.select_product(vm, :cola)
      assert vm.grid.cola == true
    end

    test "selects chips if not sold out and selected for the first time", %{vending_machine: vm} do
      vm = VendingMachine.select_product(vm, :chips)
      assert vm.grid.chips == true
    end

    test "selects candy if not sold out and selected for the first time", %{vending_machine: vm} do
      vm = VendingMachine.select_product(vm, :candy)
      assert vm.grid.candy == true
    end

    test "deselects cola if chips is selected", %{vending_machine: vm} do
      vm = VendingMachine.select_product(vm, :cola)
      vm = VendingMachine.select_product(vm, :chips)
      assert vm.grid.cola == false
    end

    test "deselects chips if cola is selected", %{vending_machine: vm} do
      vm = VendingMachine.select_product(vm, :chips)
      vm = VendingMachine.select_product(vm, :cola)
      assert vm.grid.chips == false
    end

    test "deselects candy if cola is selected", %{vending_machine: vm} do
      vm = VendingMachine.select_product(vm, :candy)
      vm = VendingMachine.select_product(vm, :cola)
      assert vm.grid.candy == false
    end

    test "deselects cola if selected again", %{vending_machine: vm} do
      vm =
        VendingMachine.select_product(vm, :cola)
        |> VendingMachine.select_product(:cola)

      assert vm.grid.cola == false
    end

    test "deselects chips if selected again", %{vending_machine: vm} do
      vm =
        VendingMachine.select_product(vm, :chips)
        |> VendingMachine.select_product(:chips)

      assert vm.grid.chips == false
    end

    test "deselects candy if selected again", %{vending_machine: vm} do
      vm =
        VendingMachine.select_product(vm, :candy)
        |> VendingMachine.select_product(:candy)

      assert vm.grid.candy == false
    end
  end

  describe "VendingMachine.select_product/2 display functionality of full Vending Machine" do
    setup do
      %{
        vending_machine: %VendingMachine{
          inventory: [
            %Product{name: :cola},
            %Product{name: :chips},
            %Product{name: :candy}
          ],
          bank: [
            @nickel,
            @nickel,
            @dime
          ]
        }
      }
    end

    test "if cola selected and staging is not enough then price of cola is displayed", %{
      vending_machine: vm
    } do
      vm = VendingMachine.select_product(vm, :cola)
      {_vm, message} = VendingMachine.check_display(vm)
      assert message == "PRICE $1.00"
    end

    test "if chips selected and staging is not enough then price of chips is displayed", %{
      vending_machine: vm
    } do
      vm = VendingMachine.select_product(vm, :chips)
      {_vm, message} = VendingMachine.check_display(vm)
      assert message == "PRICE $0.50"
    end

    test "if candy selected and staging is not enough then price of candy is displayed", %{
      vending_machine: vm
    } do
      vm = VendingMachine.select_product(vm, :candy)
      {_vm, message} = VendingMachine.check_display(vm)
      assert message == "PRICE $0.65"
    end

    test "if cola is selected and staging has enough money then THANK YOU is displayed", %{
      vending_machine: vm
    } do
      vm =
        VendingMachine.insert_coin(vm, @quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)

      vm = VendingMachine.select_product(vm, :cola)

      {_vm, message} = VendingMachine.check_display(vm)

      assert message == "THANK YOU"
    end

    test "if chips are selected and staging has enough money then THANK YOU is displayed", %{
      vending_machine: vm
    } do
      vm =
        VendingMachine.insert_coin(vm, @quarter)
        |> VendingMachine.insert_coin(@quarter)

      vm = VendingMachine.select_product(vm, :chips)

      {_vm, message} = VendingMachine.check_display(vm)

      assert message == "THANK YOU"
    end

    test "if candy is selected and staging has enough money then THANK YOU is displayed", %{
      vending_machine: vm
    } do
      vm =
        VendingMachine.insert_coin(vm, @quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)

      vm = VendingMachine.select_product(vm, :candy)

      {_vm, message} = VendingMachine.check_display(vm)

      assert message == "THANK YOU"
    end

    test "if cola is dispensed and display is checked twice then INSERT COIN is displayed",
         %{
           vending_machine: vm
         } do
      vm =
        VendingMachine.insert_coin(vm, @quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)

      vm = VendingMachine.select_product(vm, :cola)

      {vm, message} = VendingMachine.check_display(vm)

      assert message == "THANK YOU"

      {_vm, message} = VendingMachine.check_display(vm)

      assert message == "INSERT COIN"
    end

    test "if chips are dispensed and display is checked twice then INSERT COIN is displayed",
         %{
           vending_machine: vm
         } do
      vm =
        VendingMachine.insert_coin(vm, @quarter)
        |> VendingMachine.insert_coin(@quarter)

      vm = VendingMachine.select_product(vm, :chips)

      {vm, message} = VendingMachine.check_display(vm)

      assert message == "THANK YOU"

      {_vm, message} = VendingMachine.check_display(vm)

      assert message == "INSERT COIN"
    end

    test "if candy is dispensed and display is checked twice then INSERT COIN is displayed",
         %{
           vending_machine: vm
         } do
      vm =
        VendingMachine.insert_coin(vm, @quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)

      vm = VendingMachine.select_product(vm, :candy)
      {vm, message} = VendingMachine.check_display(vm)

      assert message == "THANK YOU"

      {_vm, message} = VendingMachine.check_display(vm)

      assert message == "INSERT COIN"
    end

    test "if cola is dispensed and change is returned then bank will be have $1.00 more",
         %{
           vending_machine: vm
         } do
      vm =
        VendingMachine.insert_coin(vm, @quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)

      vm = VendingMachine.select_product(vm, :cola)

      assert vm.bank == [
               @nickel,
               @nickel,
               @dime,
               @quarter,
               @quarter,
               @quarter,
               @quarter
             ]
    end

    test "if cola is dispensed and change is returned then staging will be empty",
         %{
           vending_machine: vm
         } do
      vm =
        VendingMachine.insert_coin(vm, @quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)

      vm = VendingMachine.select_product(vm, :cola)

      assert vm.staging == []
    end

    test "vending machine does not create money out of thin air", %{vending_machine: vm} do
      vm =
        VendingMachine.insert_coin(vm, @dime)
        |> VendingMachine.insert_coin(@dime)
        |> VendingMachine.insert_coin(@dime)
        |> VendingMachine.insert_coin(@dime)
        |> VendingMachine.insert_coin(@dime)
        |> VendingMachine.insert_coin(@dime)
        |> VendingMachine.insert_coin(@dime)

      vm = VendingMachine.select_product(vm, :candy)

      assert get_value_of_coins(vm.staging) + get_value_of_coins(vm.bank) +
               get_value_of_coins(vm.coin_return) == 90
    end
  end

  describe "VendingMachine.select_product/2 display functionality of non-full Vending Machine" do
    setup do
      %{
        vending_machine: %VendingMachine{}
      }
    end

    test "if cola selected and sold out then vending machine displays SOLD OUT", %{
      vending_machine: vm
    } do
      vm = VendingMachine.select_product(vm, :cola)
      {_vm, message} = VendingMachine.check_display(vm)
      assert message == "SOLD OUT"
    end

    test "if chips selected and sold out then vending machine displays SOLD OUT", %{
      vending_machine: vm
    } do
      vm = VendingMachine.select_product(vm, :chips)
      {_vm, message} = VendingMachine.check_display(vm)
      assert message == "SOLD OUT"
    end

    test "if candy selected and sold out then vending machine displays SOLD OUT", %{
      vending_machine: vm
    } do
      vm = VendingMachine.select_product(vm, :candy)
      {_vm, message} = VendingMachine.check_display(vm)
      assert message == "SOLD OUT"
    end
  end

  describe "VendingMachine.select_product/2 vending functionality of full Vending Machine" do
    setup do
      %{
        vending_machine: %VendingMachine{
          inventory: [
            %Product{name: :cola},
            %Product{name: :chips},
            %Product{name: :candy}
          ]
        }
      }
    end

    test "if cola selected and staging has enough money then product is dispensed", %{
      vending_machine: vm
    } do
      vm =
        VendingMachine.insert_coin(vm, @quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)

      vm = VendingMachine.select_product(vm, :cola)

      assert vm.bin == [%Product{name: :cola}]
    end

    test "if cola selected and not sold out and staging has enough money then cola inventory decreases by one",
         %{vending_machine: vm} do
      vm =
        VendingMachine.insert_coin(vm, @quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)

      vm = VendingMachine.select_product(vm, :cola)

      assert vm.inventory == [%Product{name: :chips}, %Product{name: :candy}]
    end

    test "if chips selected and staging has enough money then product is dispensed", %{
      vending_machine: vm
    } do
      vm =
        VendingMachine.insert_coin(vm, @quarter)
        |> VendingMachine.insert_coin(@quarter)

      vm = VendingMachine.select_product(vm, :chips)

      assert vm.bin == [%Product{name: :chips}]
    end

    test "if chips selected and not sold out and staging has enough money then chips inventory decreases by one",
         %{vending_machine: vm} do
      vm =
        VendingMachine.insert_coin(vm, @quarter)
        |> VendingMachine.insert_coin(@quarter)

      vm = VendingMachine.select_product(vm, :chips)

      assert vm.inventory == [%Product{name: :cola}, %Product{name: :candy}]
    end

    test "if candy selected and staging has enough money then product is dispensed", %{
      vending_machine: vm
    } do
      vm =
        VendingMachine.insert_coin(vm, @quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@dime)
        |> VendingMachine.insert_coin(@nickel)

      vm = VendingMachine.select_product(vm, :candy)

      assert vm.bin == [%Product{name: :candy}]
    end

    test "if candy selected and not sold out and staging has enough money then candy inventory decreases by one",
         %{vending_machine: vm} do
      vm =
        VendingMachine.insert_coin(vm, @quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@dime)
        |> VendingMachine.insert_coin(@nickel)

      vm = VendingMachine.select_product(vm, :candy)

      assert vm.inventory == [%Product{name: :cola}, %Product{name: :chips}]
    end
  end

  describe "VendingMachine.select_product/2 returns correct change" do
    setup do
      %{
        vending_machine: %VendingMachine{
          inventory: [
            %Product{name: :cola},
            %Product{name: :chips},
            %Product{name: :candy}
          ],
          bank: [
            @quarter,
            @quarter,
            @quarter,
            @quarter,
            @dime,
            @dime,
            @dime,
            @dime,
            @nickel,
            @nickel,
            @nickel,
            @nickel
          ]
        }
      }
    end

    test "If $0.75 is deposited and candy is selected then 10c is returned", %{
      vending_machine: vm
    } do
      vm =
        VendingMachine.insert_coin(vm, @quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)

      vm = VendingMachine.select_product(vm, :candy)

      assert vm.coin_return == [@dime]
    end

    test "If $1.05 is deposited and cola is selected then 5c is returned", %{vending_machine: vm} do
      vm =
        VendingMachine.insert_coin(vm, @quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@dime)
        |> VendingMachine.insert_coin(@dime)
        |> VendingMachine.insert_coin(@dime)

      vm = VendingMachine.select_product(vm, :cola)
      assert vm.coin_return == [@nickel]
    end

    test "If $0.75 is deposited and chips are selected then 25c is returned", %{
      vending_machine: vm
    } do
      vm =
        VendingMachine.insert_coin(vm, @quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)

      vm = VendingMachine.select_product(vm, :chips)
      assert vm.coin_return == [@quarter]
    end
  end

  describe "VendingMachine.can_make_change/2" do
    setup do
      %{
        vending_machine: %VendingMachine{
          inventory: [
            %Product{name: :cola},
            %Product{name: :chips},
            %Product{name: :candy}
          ],
          bank: [
            @nickel,
            @nickel,
            @dime
          ]
        }
      }
    end

    test "if change exists in staging, but not the bank it still returns true", %{
      vending_machine: vm
    } do
      vm =
        VendingMachine.insert_coin(vm, @quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@nickel)
        |> VendingMachine.insert_coin(@nickel)
        |> VendingMachine.insert_coin(@dime)

      assert VendingMachine.can_make_change(vm) == true
    end
  end
end
